import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Small persistent cache for AI responses. Values are JSON so the cache
/// survives screen rebuilds and app restarts without keeping large objects in
/// widget state.
class AiCache {
  AiCache._();

  static final SharedPreferencesAsync _prefs = SharedPreferencesAsync();
  static const String _prefix = 'karigarkart_ai_cache_';

  static Future<void> put(String key, Map<String, dynamic> value) async {
    try {
      await _prefs.setString('$_prefix$key', jsonEncode(value));
    } catch (_) {}
  }

  static Future<Map<String, dynamic>?> get(String key) async {
    try {
      final raw = await _prefs.getString('$_prefix$key');
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return null;
  }

  static Future<void> remove(String key) async {
    try {
      await _prefs.remove('$_prefix$key');
    } catch (_) {}
  }
}
