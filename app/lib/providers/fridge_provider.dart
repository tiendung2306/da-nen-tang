import 'package:flutter/material.dart';
import 'package:flutter_boilerplate/models/fridge_item.dart';
import 'package:flutter_boilerplate/services/api/api_service.dart';
import 'package:flutter_boilerplate/services/locator.dart';

class FridgeProvider extends ChangeNotifier {
  final ApiService _apiService = locator<ApiService>();

  List<FridgeItem> _items = [];
  String? _errorMessage;
  bool _isLoading = false;
  int _currentPage = 0;
  bool _isLoadingMore = false;
  bool _hasMore = true;

  List<FridgeItem> get items => _items;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;

  Future<void> fetchFridgeItems(int familyId, {bool isRefresh = false}) async {
    if (isRefresh) {
      _currentPage = 0;
      _items = [];
      _hasMore = true;
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newItems = await _apiService.getFridgeItems(familyId, page: _currentPage);
      if (newItems.isEmpty) {
        _hasMore = false;
      } else {
        _items.addAll(newItems);
        _currentPage++;
      }
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMoreItems(int familyId) async {
    if (_isLoadingMore || !_hasMore) return;
    _isLoadingMore = true;
    notifyListeners();

    try {
      final newItems = await _apiService.getFridgeItems(familyId, page: _currentPage);
      if (newItems.isEmpty) {
        _hasMore = false;
      } else {
        _items.addAll(newItems);
        _currentPage++;
      }
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> addFridgeItem(Map<String, dynamic> itemData) async {
    try {
      final newItem = await _apiService.addFridgeItem(itemData);
      _items.insert(0, newItem);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteItem(int itemId) async {
    try {
      await _apiService.deleteFridgeItem(itemId);
      _items.removeWhere((item) => item.id == itemId);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}
