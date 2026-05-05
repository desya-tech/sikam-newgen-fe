import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static late SharedPreferences _prefs;

  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  static const String _permissionsKey = 'permissions';

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Token
  static String? getToken() => _prefs.getString(_tokenKey);
  static Future<void> setToken(String token) => _prefs.setString(_tokenKey, token);
  static Future<void> removeToken() => _prefs.remove(_tokenKey);

  // User
  static String? getUserData() => _prefs.getString(_userKey);
  static Future<void> setUserData(String json) => _prefs.setString(_userKey, json);
  static Future<void> removeUserData() => _prefs.remove(_userKey);

  // Permissions
  static List<String> getPermissions() => _prefs.getStringList(_permissionsKey) ?? [];
  static Future<void> setPermissions(List<String> perms) =>
      _prefs.setStringList(_permissionsKey, perms);

  // Clear all
  static Future<void> clear() async {
    await _prefs.clear();
  }

  static bool get isLoggedIn => getToken() != null;
}
