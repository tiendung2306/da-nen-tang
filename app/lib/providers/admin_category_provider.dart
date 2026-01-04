import 'package:flutter/material.dart';
import 'package:flutter_boilerplate/models/product_model.dart' as api_models;
import '../models/category_product_model.dart';
import '../services/api/api_service.dart';

class AdminCategoryProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Category> _categories = [];
  bool _isLoading = false;
  String? _error;

  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Category _mapCategory(api_models.Category apiCategory) {
    return Category(
      id: apiCategory.id,
      name: apiCategory.name,
      description: apiCategory.description,
      isActive: true, // Assuming default, as it's not in the api model
    );
  }

  /// Lấy tất cả danh mục
  Future<void> fetchCategories() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final apiCategories = await _apiService.getCategories();
      _categories = apiCategories.map(_mapCategory).toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Tạo danh mục mới
  Future<Category> createCategory(Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newApiCategory = await _apiService.createCategory(data);
      final newCategory = _mapCategory(newApiCategory);
      _categories.add(newCategory);
      _isLoading = false;
      notifyListeners();
      return newCategory;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Cập nhật danh mục
  Future<Category> updateCategory(int id, Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedApiCategory = await _apiService.updateCategory(id, data);
      final updatedCategory = _mapCategory(updatedApiCategory);
      final index = _categories.indexWhere((c) => c.id == id);
      if (index != -1) {
        _categories[index] = updatedCategory;
      }
      _isLoading = false;
      notifyListeners();
      return updatedCategory;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Xóa danh mục
  Future<void> deleteCategory(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.deleteCategory(id);
      _categories.removeWhere((c) => c.id == id);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Tìm kiếm danh mục
  Future<List<Category>> searchCategories(String name) async {
    try {
      final apiCategories = await _apiService.searchCategories(name);
      return apiCategories.map(_mapCategory).toList();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
