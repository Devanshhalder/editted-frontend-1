import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class DataGovernor {
  DataGovernor._();
  static const _key = 'karigarkart_data_governor';
  static final _prefs = SharedPreferencesAsync();
  static bool liteMode = false;
  static bool wifiOnlySync = false;
  static int bytesToday = 0;
  static const normalImageLimit = 500 * 1024;
  static const liteImageLimit = 100 * 1024;
  static int get imageLimit => liteMode ? liteImageLimit : normalImageLimit;
  static Future<void> load() async { final raw = await _prefs.getString(_key); if (raw == null) return; try { final j = jsonDecode(raw); liteMode = j['liteMode'] == true; wifiOnlySync = j['wifiOnlySync'] == true; bytesToday = int.tryParse('${j['bytesToday'] ?? 0}') ?? 0; } catch (_) {} }
  static Future<void> save() => _prefs.setString(_key, jsonEncode({'liteMode': liteMode, 'wifiOnlySync': wifiOnlySync, 'bytesToday': bytesToday}));
  static Future<void> recordBytes(int bytes) async { bytesToday += bytes; await save(); }
}
