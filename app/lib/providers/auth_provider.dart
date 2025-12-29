import 'package:flutter/material.dart';
import 'package:flutter_boilerplate/models/auth_model.dart';
import 'package:flutter_boilerplate/providers/base_provider.dart';
import 'package:flutter_boilerplate/services/api/api_service.dart';
import 'package:flutter_boilerplate/services/locator.dart'; // Import the locator
import 'package:flutter_boilerplate/services/shared_pref/shared_pref.dart';

class AuthProvider extends BaseProvider {
  // --- ARCHITECTURE FIX: Get the ApiService instance from the locator ---
  // This ensures we are using the globally registered singleton instance.
  final ApiService _apiService = locator<ApiService>();

  UserInfo? _userInfo;
  String? _token;

  UserInfo? get userInfo => _userInfo;
  String? get token => _token;
  bool get isLoggedIn => _token != null && _userInfo != null;

  Future<void> loadUser() async {
    final storedToken = await SharedPref.getToken();
    final storedUserInfo = await SharedPref.getUserInfo();
    if (storedToken != null && storedUserInfo != null) {
      _token = storedToken;
      _userInfo = UserInfo.fromJson(storedUserInfo);
      notifyListeners();
    }
  }

  Future<void> login({required String username, required String password, String? deviceToken}) async {
    // Force a clean state before any new login attempt
    await logout();

    setStatus(ViewStatus.Loading);
    try {
      final loginData = await _apiService.login(
        username: username,
        password: password,
        deviceToken: deviceToken,
      );

      _token = loginData.token;
      _userInfo = loginData.userInfo;

      await SharedPref.saveToken(loginData.token);
      await SharedPref.saveUserInfo(loginData.userInfo.toJson());

      setStatus(ViewStatus.Ready);
      
      // This is the crucial call that should trigger the UI update
      notifyListeners();

    } catch (e) {
      setStatus(ViewStatus.Ready);
      rethrow;
    }
  }

  Future<void> logout() async {
    _token = null;
    _userInfo = null;
    await SharedPref.clear();
    notifyListeners();
  }
}
