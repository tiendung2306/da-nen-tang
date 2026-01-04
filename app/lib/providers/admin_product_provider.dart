import 'package:flutter/material.dart';
import 'package:flutter_boilerplate/models/product_model.dart' as api_models;
import '../models/category_product_model.dart';
import '../services/api/api_service.dart';

class AdminProductProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Product> _products = [];
  List<Category> _categories = [];
  bool _isLoading = false;
  String? _error;

  List<Product> get products => _products;
  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Product _mapProduct(api_models.Product apiProduct) {
    // The price is not available in the api_model.Product, so we have to get creative.
    // For now, we'll assume it might be part of the raw JSON, but since we can't
    // access it here, we'll default to 0.0. The create/update methods send price.
    return Product(
      id: apiProduct.id,
      name: apiProduct.name,
      description: apiProduct.description,
      imageUrl: apiProduct.imageUrl,
      price: 0.0, // Defaulting because it's not in the api_model.Product
      quantity: null, // Not in api model
      categoryId: apiProduct.categories?.isNotEmpty == true ? apiProduct.categories!.first.id : null,
      categoryName: apiProduct.categories?.isNotEmpty == true ? apiProduct.categories!.first.name : null,
      isActive: apiProduct.isActive,
    );
  }

  Category _mapCategory(api_models.Category apiCategory) {
    return Category(
      id: apiCategory.id,
      name: apiCategory.name,
      description: apiCategory.description,
      isActive: true, // Assuming default
    );
  }

  /// Lấy tất cả sản phẩm
  Future<void> fetchProducts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final apiProducts = await _apiService.getProducts();
      _products = apiProducts.map(_mapProduct).toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Lấy danh mục (dùng cho dropdown)
  Future<void> fetchCategories() async {
    try {
      final apiCategories = await _apiService.getCategories();
      _categories = apiCategories.map(_mapCategory).toList();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Tạo sản phẩm mới
  Future<Product> createProduct(Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newApiProduct = await _apiService.createProduct(data);
      final newProduct = _mapProduct(newApiProduct);
      _products.add(newProduct);
      _isLoading = false;
      notifyListeners();
      return newProduct;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Cập nhật sản phẩm
  Future<Product> updateProduct(int id, Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedApiProduct = await _apiService.updateProduct(id, data);
      final updatedProduct = _mapProduct(updatedApiProduct);
      final index = _products.indexWhere((p) => p.id == id);
      if (index != -1) {
        _products[index] = updatedProduct;
      }
      _isLoading = false;
      notifyListeners();
      return updatedProduct;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Xóa sản phẩm
  Future<void> deleteProduct(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.deleteProduct(id);
      _products.removeWhere((p) => p.id == id);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Tìm kiếm sản phẩm
  Future<List<Product>> searchProducts(String name) async {
    try {
      final apiProducts = await _apiService.searchProducts(name);
      return apiProducts.map(_mapProduct).toList();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  /// Lấy sản phẩm theo danh mục
  Future<List<Product>> getProductsByCategory(int categoryId) async {
    try {
      final apiProducts = await _apiService.getProductsByCategory(categoryId);
      return apiProducts.map(_mapProduct).toList();
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
