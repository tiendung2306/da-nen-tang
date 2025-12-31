import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_boilerplate/models/auth_model.dart';
import 'package:flutter_boilerplate/services/api/api_service.dart';
import 'package:flutter_boilerplate/services/locator.dart';
import 'package:flutter_boilerplate/services/shared_pref/shared_pref.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = locator<ApiService>();

  UserInfo? _userInfo;
  bool _isLoggedIn = false;
  String? _errorMessage;
  bool _isLoading = false;

  UserInfo? get userInfo => _userInfo;
  bool get isLoggedIn => _isLoggedIn;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;

  AuthProvider() {
    loadUser();
  }

  Future<void> loadUser() async {
    _isLoading = true;
    notifyListeners();

    final token = await SharedPref.getToken();
    if (token != null) {
      try {
        _userInfo = await _apiService.getCurrentUser();
        _isLoggedIn = true;
      } catch (e) {
        // If token is invalid, logout
        await logout();
      }
    } else {
      _isLoggedIn = false;
      _userInfo = null;
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final loginData = await _apiService.login(username: username, password: password);
      await SharedPref.setToken(loginData.accessToken);
      
      // After setting token, let loadUser handle the state update and UI notification
      await loadUser(); 
      
      return _isLoggedIn; 
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoggedIn = false;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await SharedPref.removeToken();
    _isLoggedIn = false;
    _userInfo = null;
    notifyListeners();
  }

  Future<bool> register(Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _apiService.register(data);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> uploadAvatar(XFile image) async {
    try {
      final updatedUser = await _apiService.uploadUserAvatar(image);
      _userInfo = updatedUser;
      notifyListeners();
    } catch (e) {
      // handle error
    }
  }

  Future<void> deleteAvatar() async {
    try {
      final updatedUser = await _apiService.deleteUserAvatar();
      _userInfo = updatedUser;
      notifyListeners();
    } catch (e) {
      // handle error
    }
  }
}
