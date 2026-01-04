import 'package:flutter/material.dart';
import '../models/admin_user_model.dart';
import '../services/api/api_service.dart';

class AdminUserProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<AdminUser> _users = [];
  bool _isLoading = false;
  String? _error;
  int _currentPage = 0;
  int _pageSize = 10;
  int _totalElements = 0;

  // Getters
  List<AdminUser> get users => _users;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentPage => _currentPage;
  int get pageSize => _pageSize;
  int get totalElements => _totalElements;
  int get totalPages => (_totalElements / _pageSize).ceil();

  /// Lấy danh sách user với phân trang
  Future<void> fetchUsers({int? page, int? size}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.getAdminUsers(
        page: page ?? _currentPage,
        size: size ?? _pageSize,
      );

      if (response is Map<String, dynamic>) {
        _currentPage = response['currentPage'] ?? _currentPage;
        _pageSize = response['pageSize'] ?? _pageSize;
        _totalElements = response['totalElements'] ?? 0;

        // Parse user list
        final userList = response['content'] as List?;
        _users = userList
                ?.map((u) => AdminUser.fromJson(u as Map<String, dynamic>))
                .toList() ??
            [];
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Lấy chi tiết user theo ID
  Future<AdminUser> getUserById(int id) async {
    try {
      final response = await _apiService.getAdminUserById(id);
      return AdminUser.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Tạo user mới
  Future<AdminUser> createUser(Map<String, dynamic> userData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.createAdminUser(userData);
      final newUser = AdminUser.fromJson(response as Map<String, dynamic>);
      _users.add(newUser);
      _isLoading = false;
      notifyListeners();
      return newUser;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Cập nhật trạng thái user (active/inactive)
  Future<AdminUser> updateUserStatus(int id, bool isActive) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.updateAdminUserStatus(id, isActive);
      final updatedUser = AdminUser.fromJson(response as Map<String, dynamic>);

      // Update in list
      final index = _users.indexWhere((u) => u.id == id);
      if (index != -1) {
        _users[index] = updatedUser;
      }

      _isLoading = false;
      notifyListeners();
      return updatedUser;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Cập nhật vai trò của user
  Future<AdminUser> updateUserRoles(int id, List<String> roles) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.updateAdminUserRoles(id, roles);
      final updatedUser = AdminUser.fromJson(response as Map<String, dynamic>);

      // Update in list
      final index = _users.indexWhere((u) => u.id == id);
      if (index != -1) {
        _users[index] = updatedUser;
      }

      _isLoading = false;
      notifyListeners();
      return updatedUser;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Đặt lại mật khẩu cho user
  Future<void> resetUserPassword(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.resetAdminUserPassword(id);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Xóa user
  Future<void> deleteUser(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.deleteAdminUser(id);
      _users.removeWhere((u) => u.id == id);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Đi tới trang tiếp theo
  Future<void> nextPage() async {
    if (_currentPage < totalPages - 1) {
      await fetchUsers(page: _currentPage + 1);
    }
  }

  /// Quay lại trang trước
  Future<void> previousPage() async {
    if (_currentPage > 0) {
      await fetchUsers(page: _currentPage - 1);
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
