import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  SessionService._();

  static const String _loggedInKey = 'karigarkart_logged_in';

  static Future<SharedPreferences> get _preferences async {
    return SharedPreferences.getInstance();
  }

  static Future<bool> isLoggedIn() async {
    final preferences = await _preferences;
    return preferences.getBool(_loggedInKey) ?? false;
  }

  static Future<void> setLoggedIn(bool value) async {
    final preferences = await _preferences;
    await preferences.setBool(_loggedInKey, value);
  }

  static Future<void> clearSession() async {
    final preferences = await _preferences;
    await preferences.remove(_loggedInKey);
  }
}
