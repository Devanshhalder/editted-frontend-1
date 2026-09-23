import 'package:shared_preferences/shared_preferences.dart';

class ProfileStorage {
  ProfileStorage._();

  static const _nameKey = 'profile_name';
  static const _locationKey = 'profile_location';
  static const _shopKey = 'profile_shop';
  static const _contactKey = 'profile_contact';

  static final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  static Future<Map<String, String>> load() async {
    final name = await _prefs.getString(_nameKey);
    final location = await _prefs.getString(_locationKey);
    final shop = await _prefs.getString(_shopKey);
    final contact = await _prefs.getString(_contactKey);

    return {
      'name': name?.trim().isNotEmpty == true ? name!.trim() : 'USER',
      'location':
      location?.trim().isNotEmpty == true ? location!.trim() : 'MP INDIA',
      'shop': shop?.trim().isNotEmpty == true
          ? shop!.trim()
          : 'User handicrafts',
      'contact': contact?.trim() ?? '',
    };
  }

  static Future<void> save({
    required String name,
    required String location,
    required String shop,
    required String contact,
  }) async {
    await _prefs.setString(_nameKey, name.trim().isEmpty ? 'USER' : name.trim());
    await _prefs.setString(
      _locationKey,
      location.trim().isEmpty ? 'MP INDIA' : location.trim(),
    );
    await _prefs.setString(
      _shopKey,
      shop.trim().isEmpty ? 'User handicrafts' : shop.trim(),
    );
    await _prefs.setString(_contactKey, contact.trim());
  }
}
