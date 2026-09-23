import 'package:shared_preferences/shared_preferences.dart';

class ArtisanIdentityStorage {
  ArtisanIdentityStorage._();

  static const _pehchanKey = 'artisan_pehchan_id';
  static const _giKey = 'artisan_gi_tag';
  static const _affiliationKey = 'artisan_affiliation';

  static final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  static Future<Map<String, String>> load() async => {
        'pehchanId': (await _prefs.getString(_pehchanKey))?.trim() ?? '',
        'giTag': (await _prefs.getString(_giKey))?.trim() ?? '',
        'affiliation': (await _prefs.getString(_affiliationKey))?.trim() ?? '',
      };

  static Future<void> save({
    required String pehchanId,
    required String giTag,
    required String affiliation,
  }) async {
    await _prefs.setString(_pehchanKey, pehchanId.trim());
    await _prefs.setString(_giKey, giTag.trim());
    await _prefs.setString(_affiliationKey, affiliation.trim());
  }
}
