import 'package:flutter/material.dart';
import 'package:flutter_boilerplate/models/fridge_item.dart';
import 'package:flutter_boilerplate/models/fridge_statistics.dart';
import 'package:flutter_boilerplate/providers/base_provider.dart';
import 'package:flutter_boilerplate/services/api/api_service.dart';
import 'package:flutter_boilerplate/services/locator.dart';

enum FridgeFilterType { all, active, expiring, expired }

enum FridgeLocationFilter { all, freezer, cooler, pantry }

enum FridgeSortType {
  expirationNewest,  // Hạn sử dụng: mới đến cũ
  expirationOldest,  // Hạn sử dụng: cũ đến mới
  nameAZ,            // Tên: A-Z
  nameZA,            // Tên: Z-A
}

class FridgeProvider extends BaseProvider {
  final ApiService _apiService = locator<ApiService>();

  List<FridgeItem> _items = [];
  FridgeStatistics? _statistics;
  String? _errorMessage;
  FridgeFilterType _currentFilter = FridgeFilterType.all;
  FridgeLocationFilter _currentLocationFilter = FridgeLocationFilter.all;
  FridgeSortType _currentSort = FridgeSortType.expirationOldest;

  int _currentPage = 0;
  bool _isLoadingMore = false;
  bool _hasMore = true;

  List<FridgeItem> get items => _items;
  FridgeStatistics? get statistics => _statistics;
  String? get errorMessage => _errorMessage;
  bool get isLoadingMore => _isLoadingMore;
  FridgeFilterType get currentFilter => _currentFilter;
  FridgeLocationFilter get currentLocationFilter => _currentLocationFilter;
  FridgeSortType get currentSort => _currentSort;

  // Getter trả về danh sách đã lọc theo ngăn và sắp xếp
  List<FridgeItem> get sortedItems {
    // Lọc theo ngăn trước
    List<FridgeItem> filtered;
    switch (_currentLocationFilter) {
      case FridgeLocationFilter.freezer:
        filtered = _items.where((item) => item.location.toUpperCase() == 'FREEZER').toList();
        break;
      case FridgeLocationFilter.cooler:
        filtered = _items.where((item) => item.location.toUpperCase() == 'COOLER').toList();
        break;
      case FridgeLocationFilter.pantry:
        filtered = _items.where((item) => item.location.toUpperCase() == 'PANTRY').toList();
        break;
      case FridgeLocationFilter.all:
      default:
        filtered = List<FridgeItem>.from(_items);
    }

    // Sau đó sắp xếp
    switch (_currentSort) {
      case FridgeSortType.expirationNewest:
        filtered.sort((a, b) {
          if (a.expirationDate == null && b.expirationDate == null) return 0;
          if (a.expirationDate == null) return 1;
          if (b.expirationDate == null) return -1;
          return b.expirationDate!.compareTo(a.expirationDate!);
        });
        break;
      case FridgeSortType.expirationOldest:
        filtered.sort((a, b) {
          if (a.expirationDate == null && b.expirationDate == null) return 0;
          if (a.expirationDate == null) return 1;
          if (b.expirationDate == null) return -1;
          return a.expirationDate!.compareTo(b.expirationDate!);
        });
        break;
      case FridgeSortType.nameAZ:
        filtered.sort((a, b) => a.productName.toLowerCase().compareTo(b.productName.toLowerCase()));
        break;
      case FridgeSortType.nameZA:
        filtered.sort((a, b) => b.productName.toLowerCase().compareTo(a.productName.toLowerCase()));
        break;
    }
    return filtered;
  }

  void setSort(FridgeSortType sort) {
    _currentSort = sort;
    notifyListeners();
  }

  void setLocationFilter(FridgeLocationFilter filter) {
    _currentLocationFilter = filter;
    notifyListeners();
  }

  void setFilter(FridgeFilterType filter) {
    _currentFilter = filter;
    notifyListeners();
  }

  Future<void> fetchFridgeItems(int familyId, {bool isRefresh = false}) async {
    if (isRefresh) {
      _currentPage = 0;
      _items = [];
      _hasMore = true;
    }
    setStatus(ViewStatus.Loading);
    _errorMessage = null;
    try {
      List<FridgeItem> newItems;
      switch (_currentFilter) {
        case FridgeFilterType.active:
          newItems = await _apiService.getActiveFridgeItems(familyId, page: _currentPage);
          break;
        case FridgeFilterType.expiring:
          newItems = await _apiService.getExpiringFridgeItems(familyId, page: _currentPage);
          break;
        case FridgeFilterType.expired:
          newItems = await _apiService.getExpiredFridgeItems(familyId, page: _currentPage);
          break;
        case FridgeFilterType.all:
        default:
          newItems = await _apiService.getFridgeItems(familyId, page: _currentPage);
      }
      if (newItems.isEmpty) {
        _hasMore = false;
      } else {
        _items.addAll(newItems);
        _currentPage++;
      }
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      setStatus(ViewStatus.Ready);
    }
  }

  Future<void> fetchMoreItems(int familyId) async {
    if (_isLoadingMore || !_hasMore) return;
    _isLoadingMore = true;
    notifyListeners();
    try {
      List<FridgeItem> newItems;
      switch (_currentFilter) {
        case FridgeFilterType.active:
          newItems = await _apiService.getActiveFridgeItems(familyId, page: _currentPage);
          break;
        case FridgeFilterType.expiring:
          newItems = await _apiService.getExpiringFridgeItems(familyId, page: _currentPage);
          break;
        case FridgeFilterType.expired:
          newItems = await _apiService.getExpiredFridgeItems(familyId, page: _currentPage);
          break;
        case FridgeFilterType.all:
        default:
          newItems = await _apiService.getFridgeItems(familyId, page: _currentPage);
      }
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

  Future<void> fetchStatistics(int familyId) async {
    try {
      _statistics = await _apiService.getFridgeStatistics(familyId);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  Future<void> addFridgeItem(Map<String, dynamic> itemData) async {
    try {
      final newItem = await _apiService.addFridgeItem(itemData);
      _items.insert(0, newItem);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateFridgeItem(int itemId, Map<String, dynamic> itemData) async {
    try {
      final updatedItem = await _apiService.updateFridgeItem(itemId, itemData);
      final index = _items.indexWhere((item) => item.id == itemId);
      if (index != -1) {
        _items[index] = updatedItem;
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      rethrow;
    }
  }

  Future<void> consumeItem(int itemId, {double? quantityUsed}) async {
    try {
      final updatedItem = await _apiService.consumeFridgeItem(itemId, quantityUsed: quantityUsed);
      final index = _items.indexWhere((item) => item.id == itemId);
      if (index != -1) {
        _items[index] = updatedItem;
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      rethrow;
    }
  }

  Future<void> discardItem(int itemId) async {
    try {
      final updatedItem = await _apiService.discardFridgeItem(itemId);
      final index = _items.indexWhere((item) => item.id == itemId);
      if (index != -1) {
        _items[index] = updatedItem;
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
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
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      rethrow;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

