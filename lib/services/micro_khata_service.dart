import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class KhataEntry {
  const KhataEntry({required this.amount, required this.status, required this.date, required this.note});
  final double amount;
  final String status;
  final String date;
  final String note;
  Map<String, dynamic> toJson() => {'amount': amount, 'status': status, 'date': date, 'note': note};
  factory KhataEntry.fromJson(Map<String, dynamic> j) => KhataEntry(amount: double.tryParse('${j['amount']}') ?? 0, status: '${j['status'] ?? 'cleared'}', date: '${j['date'] ?? ''}', note: '${j['note'] ?? ''}');
}

class MicroKhataService {
  MicroKhataService._();
  static const _key = 'karigarkart_micro_khata';
  static final _prefs = SharedPreferencesAsync();
  static Future<List<KhataEntry>> read() async {
    final raw = await _prefs.getString(_key);
    if (raw == null) return [];
    try { return (jsonDecode(raw) as List).whereType<Map>().map((e) => KhataEntry.fromJson(Map<String, dynamic>.from(e))).toList(); } catch (_) { return []; }
  }
  static Future<void> add(KhataEntry entry) async {
    final entries = await read(); entries.add(entry);
    await _prefs.setString(_key, jsonEncode(entries.map((e) => e.toJson()).toList()));
  }
}
