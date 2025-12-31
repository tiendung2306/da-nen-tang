import 'package:flutter/material.dart';
import 'package:flutter_boilerplate/models/auth_model.dart';
import 'package:flutter_boilerplate/services/api/api_service.dart';
import 'package:flutter_boilerplate/services/locator.dart';
import 'package:flutter_boilerplate/services/shared_pref/shared_pref.dart';

// RE-ARCHITECTED: Inherit directly from ChangeNotifier to isolate the issue.
class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = locator<ApiService>();

  UserInfo? _userInfo;
  String? _token;
  bool _isLoading = false; // Manage loading state locally.

  UserInfo? get userInfo => _userInfo;
  String? get token => _token;
  bool get isLoading => _isLoading;
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
    _isLoading = true;
    notifyListeners(); // Notify UI that loading has started.

    try {
      final loginData = await _apiService.login(
        username: username,
        password: password,
        deviceToken: deviceToken,
      );

      // Set the state that determines login status.
      _token = loginData.token;
      _userInfo = loginData.userInfo;
      
      // Persist the session.
      await SharedPref.saveToken(loginData.token);
      await SharedPref.saveUserInfo(loginData.userInfo.toJson());

      _isLoading = false;
      // The crucial notification that will trigger navigation in main.dart.
      notifyListeners(); 

    } catch (e) {
      _isLoading = false;
      notifyListeners(); // Notify UI that loading is over.
      rethrow; // Re-throw the error to be displayed on the login page.
    }
  }

  Future<void> logout() async {
    _token = null;
    _userInfo = null;
    _isLoading = false;
    await SharedPref.clear();
    notifyListeners();
  }
}
