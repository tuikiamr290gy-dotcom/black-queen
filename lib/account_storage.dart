import 'package:shared_preferences/shared_preferences.dart';

class AccountStorage {
  static const String _nameKey = 'black_queen_player_name_v1';
  static const String _typeKey = 'black_queen_account_type_v1';

  static Future<String?> loadName() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_nameKey)?.trim();
    return (name == null || name.isEmpty) ? null : name;
  }

  static Future<String> loadAccountType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_typeKey) ?? 'Guest';
  }

  static Future<void> saveGuestName(String name) async {
    final clean = name.trim();
    if (clean.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, clean);
    await prefs.setString(_typeKey, 'Guest');
  }

  static Future<void> clearAccount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_nameKey);
    await prefs.remove(_typeKey);
  }
}
