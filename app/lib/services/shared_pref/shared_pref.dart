import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// Constants for keys
const String _authTokenKey = 'auth_token';
const String _userInfoKey = 'user_info';

class SharedPref {
  static late SharedPreferences _sharedPref;

  // Private constructor
  SharedPref._();

  static Future<void> init() async {
    _sharedPref = await SharedPreferences.getInstance();
  }

  static Future<void> clear() async {
    await _sharedPref.clear();
  }

  // --- Token Management ---
  static Future<void> saveToken(String token) async {
    await _sharedPref.setString(_authTokenKey, token);
  }

  static Future<String?> getToken() async {
    return _sharedPref.getString(_authTokenKey);
  }

  // --- User Info Management ---
  static Future<void> saveUserInfo(Map<String, dynamic> userInfo) async {
    await _sharedPref.setString(_userInfoKey, json.encode(userInfo));
  }

  static Future<Map<String, dynamic>?> getUserInfo() async {
    final userInfoString = _sharedPref.getString(_userInfoKey);
    if (userInfoString != null) {
      return json.decode(userInfoString) as Map<String, dynamic>;
    }
    return null;
  }
}
