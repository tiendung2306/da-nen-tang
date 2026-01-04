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
    // Map from the API Product model to the UI Product model
    return Product(
      id: apiProduct.id,
      name: apiProduct.name,
      defaultUnit: apiProduct.defaultUnit,
      avgShelfLife: apiProduct.avgShelfLife,
      description: apiProduct.description,
      imageUrl: apiProduct.imageUrl,
      categoryId: apiProduct.categories?.isNotEmpty == true
          ? apiProduct.categories!.first.id
          : null,
      isActive: apiProduct.isActive,
    );
  }

  Product _mapAdminProduct(dynamic adminProduct) {
    return Product(
      id: adminProduct?.id as int?,
      name: adminProduct?.name as String?,
      defaultUnit: adminProduct?.defaultUnit as String?,
      avgShelfLife: adminProduct?.avgShelfLife as int?,
      description: adminProduct?.description as String?,
      imageUrl: adminProduct?.imageUrl as String?,
      categoryId: adminProduct?.categoryId as int?,
      isActive: adminProduct?.isActive as bool?,
    );
  }

  Category _mapCategory(dynamic apiCategory) {
    return Category(
      id: apiCategory?.id as int?,
      name: apiCategory?.name as String?,
      description: apiCategory?.description as String?,
      isActive: apiCategory?.isActive as bool? ?? true, // Assuming default
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
  Future<Product> createProduct(Map<String, dynamic> data,
      {dynamic image}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newApiProduct = await _apiService.createProduct(data, image: image);
      final newProduct = _mapAdminProduct(newApiProduct);
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
  Future<Product> updateProduct(int id, Map<String, dynamic> data,
      {dynamic image}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedApiProduct =
          await _apiService.updateProduct(id, data, image: image);
      final updatedProduct = _mapAdminProduct(updatedApiProduct);
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
