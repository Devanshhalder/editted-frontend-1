import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ai_idempotency.dart';

class OfflineRequest {
  const OfflineRequest({required this.id, required this.type, required this.payload, required this.createdAt});
  final String id;
  final String type;
  final Map<String, dynamic> payload;
  final int createdAt;
  Map<String, dynamic> toJson() => {'id': id, 'type': type, 'payload': payload, 'createdAt': createdAt};
  factory OfflineRequest.fromJson(Map<String, dynamic> json) => OfflineRequest(id: json['id'].toString(), type: json['type'].toString(), payload: Map<String, dynamic>.from(json['payload'] as Map? ?? const {}), createdAt: int.tryParse(json['createdAt'].toString()) ?? DateTime.now().millisecondsSinceEpoch);
}

class OfflineRequestQueue {
  OfflineRequestQueue._();
  static const _queueKey = 'karigarkart_offline_request_queue';
  static const _wifiOnlyKey = 'karigarkart_sync_wifi_only';
  static final SharedPreferencesAsync _prefs = SharedPreferencesAsync();
  static final Connectivity _connectivity = Connectivity();
  static StreamSubscription<List<ConnectivityResult>>? _subscription;
  static Future<void> Function(OfflineRequest request)? _dispatcher;
  static bool _started = false;
  static bool _flushing = false;

  static Future<void> initialize() async {
    if (_started) return;
    _started = true;
    _subscription = _connectivity.onConnectivityChanged.listen((result) async {
      if (await _canSyncFrom(result)) await flush();
    });
    try {
      if (await _canSyncNow()) await flush();
    } catch (_) {}
  }

  static void registerDispatcher(Future<void> Function(OfflineRequest request) dispatcher) { _dispatcher = dispatcher; }
  static Future<bool> isOnline() async { try { return _isOnline(await _connectivity.checkConnectivity()); } catch (_) { return false; } }
  static bool _isOnline(List<ConnectivityResult> result) => result.any((item) => item != ConnectivityResult.none);
  static bool _isWifi(List<ConnectivityResult> result) => result.any((item) => item == ConnectivityResult.wifi || item == ConnectivityResult.ethernet);
  static Future<bool> get wifiOnly async => await _prefs.getBool(_wifiOnlyKey) ?? false;
  static Future<void> setWifiOnly(bool value) async { await _prefs.setBool(_wifiOnlyKey, value); if (!value) await flush(); }

  static Future<bool> _canSyncNow() async {
    try { return await _canSyncFrom(await _connectivity.checkConnectivity()); } catch (_) { return false; }
  }
  static Future<bool> _canSyncFrom(List<ConnectivityResult> result) async {
    if (!_isOnline(result)) return false;
    if (await wifiOnly) return _isWifi(result);
    return true;
  }

  static Future<void> enqueue({required String type, required Map<String, dynamic> payload}) async {
    final current = await _read();
    final key = aiIdempotencyKey(type, payload);
    if (current.any((item) => item.id == key)) return;
    current.add(OfflineRequest(id: key, type: type, payload: {...payload, 'idempotency_key': key}, createdAt: DateTime.now().millisecondsSinceEpoch));
    await _write(current);
    if (await _canSyncNow()) await flush();
  }

  static Future<List<OfflineRequest>> pendingRequests() => _read();
  static Future<int> pendingCount() async => (await _read()).length;

  static Future<void> retry(String id) async {
    final requests = await _read();
    final index = requests.indexWhere((item) => item.id == id);
    if (index < 0) return;
    final item = requests.removeAt(index);
    requests.insert(0, item);
    await _write(requests);
    if (await _canSyncNow()) await flush();
  }

  static Future<void> remove(String id) async {
    final requests = await _read();
    requests.removeWhere((item) => item.id == id);
    await _write(requests);
  }

  static Future<void> flush() async {
    if (_flushing || _dispatcher == null || !await _canSyncNow()) return;
    _flushing = true;
    try {
      final requests = await _read();
      if (requests.isEmpty) return;
      final remaining = <OfflineRequest>[];
      for (final request in requests) {
        try { await _dispatcher!(request); } catch (_) { remaining.add(request); }
      }
      await _write(remaining);
    } finally { _flushing = false; }
  }

  static Future<List<OfflineRequest>> _read() async {
    final raw = await _prefs.getString(_queueKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded.whereType<Map>().map((item) => OfflineRequest.fromJson(Map<String, dynamic>.from(item))).toList();
    } catch (_) { return []; }
  }
  static Future<void> _write(List<OfflineRequest> requests) async => _prefs.setString(_queueKey, jsonEncode(requests.map((request) => request.toJson()).toList()));
  static Future<void> dispose() async { await _subscription?.cancel(); _subscription = null; _started = false; }
}
