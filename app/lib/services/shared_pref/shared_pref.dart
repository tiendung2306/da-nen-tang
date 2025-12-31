import 'package:shared_preferences/shared_preferences.dart';

class SharedPref {
  static const String _tokenKey = 'auth_token';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static Future<void> setToken(String token) async {
    await _prefs?.setString(_tokenKey, token);
  }

  static Future<String?> getToken() async {
    return _prefs?.getString(_tokenKey);
  }

  static Future<void> removeToken() async {
    await _prefs?.remove(_tokenKey);
  }
}
