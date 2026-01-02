import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_boilerplate/models/shopping_list_model.dart';
import 'package:flutter_boilerplate/providers/base_provider.dart';
import 'package:flutter_boilerplate/services/api/api_service.dart';
import 'package:flutter_boilerplate/services/locator.dart';

class ShoppingListProvider extends BaseProvider {
  final ApiService _apiService = locator<ApiService>();
  final Map<int, Timer> _debounceTimers = {};
  final Map<int, _PendingUpdate> _pendingUpdates = {};

  List<ShoppingList> _shoppingLists = [];
  List<ShoppingList> get shoppingLists => _shoppingLists;

  ShoppingList? _currentShoppingList;
  ShoppingList? get currentShoppingList => _currentShoppingList;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Fetch all shopping lists for a family
  Future<void> fetchShoppingLists(int familyId) async {
    setStatus(ViewStatus.Loading);
    _errorMessage = null;
    try {
      _shoppingLists = await _apiService.getShoppingLists(familyId);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      setStatus(ViewStatus.Ready);
    }
  }

  // Fetch active shopping lists for a family
  Future<void> fetchActiveShoppingLists(int familyId) async {
    setStatus(ViewStatus.Loading);
    _errorMessage = null;
    try {
      _shoppingLists = await _apiService.getActiveShoppingLists(familyId);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      setStatus(ViewStatus.Ready);
    }
  }

  // Fetch items for a specific shopping list
  Future<void> fetchShoppingListItems(int listId) async {
    _errorMessage = null;
    try {
      final detailedList = await _apiService.getShoppingListById(listId);
      final index = _shoppingLists.indexWhere((list) => list.id == listId);
      if (index != -1) {
        _shoppingLists[index] = detailedList;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  // Get shopping list details by ID
  Future<void> fetchShoppingListDetails(int listId) async {
    setStatus(ViewStatus.Loading);
    _errorMessage = null;
    try {
      _currentShoppingList = await _apiService.getShoppingListById(listId);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      setStatus(ViewStatus.Ready);
    }
  }

  // Create a new shopping list
  Future<ShoppingList?> createShoppingList({
    required int familyId,
    required String name,
    String? description,
    int? assignedToId,
    List<CreateShoppingItemRequest>? items,
  }) async {
    _errorMessage = null;
    try {
      final data = {
        'familyId': familyId,
        'name': name,
        if (description != null) 'description': description,
        if (assignedToId != null) 'assignedToId': assignedToId,
        if (items != null) 'items': items.map((e) => e.toJson()).toList(),
      };
      final newList = await _apiService.createShoppingList(data);
      _shoppingLists.insert(0, newList);
      notifyListeners();
      return newList;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  // Update shopping list status with retry on conflict
  Future<bool> updateShoppingListStatus(int listId, ShoppingListStatus status, {required int version, int retryCount = 0}) async {
    _errorMessage = null;
    try {
      final updatedList = await _apiService.updateShoppingList(listId, {
        'status': status.name,
        'version': version,
      });
      final index = _shoppingLists.indexWhere((list) => list.id == listId);
      if (index != -1) {
        _shoppingLists[index] = updatedList;
      }
      if (_currentShoppingList?.id == listId) {
        _currentShoppingList = updatedList;
      }
      notifyListeners();
      return true;
    } catch (e) {
      final errorMsg = e.toString().replaceFirst('Exception: ', '');
      
      // Check if it's a conflict/concurrency error
      if ((errorMsg.contains('conflict') || errorMsg.contains('concurrency') || errorMsg.contains('409')) && retryCount < 2) {
        // Retry with fresh data - fetch latest version
        try {
          await fetchShoppingListDetails(listId);
          final freshList = _currentShoppingList;
          if (freshList != null && freshList.id == listId) {
            // Retry with new version
            return await updateShoppingListStatus(listId, status, version: freshList.version ?? 0, retryCount: retryCount + 1);
          }
        } catch (_) {
          // If refresh fails, show original error
        }
      }
      
      _errorMessage = errorMsg;
      notifyListeners();
      return false;
    }
  }

  // Update shopping list (name, description, assignedTo) with retry on conflict
  Future<ShoppingList?> updateShoppingList({
    required int listId,
    required int version,
    String? name,
    String? description,
    int? assignedToId,
    int retryCount = 0,
  }) async {
    _errorMessage = null;
    try {
      final data = <String, dynamic>{
        'version': version,
        if (name != null) 'name': name,
        if (description != null) 'description': description,
        if (assignedToId != null) 'assignedToId': assignedToId,
      };
      final updatedList = await _apiService.updateShoppingList(listId, data);
      final index = _shoppingLists.indexWhere((list) => list.id == listId);
      if (index != -1) {
        _shoppingLists[index] = updatedList;
      }
      if (_currentShoppingList?.id == listId) {
        _currentShoppingList = updatedList;
      }
      notifyListeners();
      return updatedList;
    } catch (e) {
      final errorMsg = e.toString().replaceFirst('Exception: ', '');
      
      // Check if it's a conflict/concurrency error
      if ((errorMsg.contains('conflict') || errorMsg.contains('concurrency') || errorMsg.contains('409')) && retryCount < 2) {
        // Retry with fresh data
        try {
          await fetchShoppingListDetails(listId);
          final freshList = _currentShoppingList;
          if (freshList != null && freshList.id == listId) {
            // Retry with new version
            return await updateShoppingList(
              listId: listId,
              version: freshList.version ?? 0,
              name: name,
              description: description,
              assignedToId: assignedToId,
              retryCount: retryCount + 1,
            );
          }
        } catch (_) {
          // If refresh fails, show original error
        }
      }
      
      _errorMessage = errorMsg;
      notifyListeners();
      return null;
    }
  }

  // Delete a shopping list
  Future<bool> deleteShoppingList(int listId) async {
    _errorMessage = null;
    try {
      await _apiService.deleteShoppingList(listId);
      _shoppingLists.removeWhere((list) => list.id == listId);
      if (_currentShoppingList?.id == listId) {
        _currentShoppingList = null;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // Add a single item to shopping list
  Future<void> addShoppingItem(int listId, CreateShoppingItemRequest item) async {
    _errorMessage = null;
    try {
      final newItem = await _apiService.addShoppingItem(listId, item.toJson());
      if (_currentShoppingList?.id == listId && _currentShoppingList?.items != null) {
        final updatedItems = [..._currentShoppingList!.items!, newItem];
        _currentShoppingList = ShoppingList(
          id: _currentShoppingList!.id,
          name: _currentShoppingList!.name,
          description: _currentShoppingList!.description,
          familyId: _currentShoppingList!.familyId,
          status: _currentShoppingList!.status,
          version: _currentShoppingList!.version,
          createdBy: _currentShoppingList!.createdBy,
          createdAt: _currentShoppingList!.createdAt,
          updatedAt: DateTime.now(),
          items: updatedItems,
        );
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  // Add multiple items to shopping list
  Future<void> addShoppingItemsBulk(int listId, List<CreateShoppingItemRequest> items) async {
    _errorMessage = null;
    try {
      final newItems = await _apiService.addShoppingItemsBulk(
        listId, 
        items.map((e) => e.toJson()).toList(),
      );
      if (_currentShoppingList?.id == listId && _currentShoppingList?.items != null) {
        final updatedItems = [..._currentShoppingList!.items!, ...newItems];
        _currentShoppingList = ShoppingList(
          id: _currentShoppingList!.id,
          name: _currentShoppingList!.name,
          description: _currentShoppingList!.description,
          familyId: _currentShoppingList!.familyId,
          status: _currentShoppingList!.status,
          version: _currentShoppingList!.version,
          createdBy: _currentShoppingList!.createdBy,
          createdAt: _currentShoppingList!.createdAt,
          updatedAt: DateTime.now(),
          items: updatedItems,
        );
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  // Toggle item bought status with debounce
  Future<void> toggleItemBought(int itemId, bool isBought, {int? version}) async {
    // Hủy timer cũ nếu đang chờ
    _debounceTimers[itemId]?.cancel();
    
    // Tìm item hiện tại để lấy version mới nhất nếu không được cung cấp
    if (version == null) {
      for (var list in _shoppingLists) {
        if (list.items != null) {
          try {
            final item = list.items!.firstWhere((item) => item.id == itemId);
            version = item.version ?? 0;
            break;
          } catch (_) {}
        }
      }
      if (version == null && _currentShoppingList?.items != null) {
        try {
          final item = _currentShoppingList!.items!.firstWhere((item) => item.id == itemId);
          version = item.version ?? 0;
        } catch (_) {
          version = 0;
        }
      }
      version ??= 0;
    }
    
    // Optimistic update - cập nhật UI ngay lập tức
    ShoppingItem? oldItem;
    int? listIndex;
    int? itemIndex;
    
    // Tìm và cập nhật trong _shoppingLists
    for (int i = 0; i < _shoppingLists.length; i++) {
      if (_shoppingLists[i].items != null) {
        final idx = _shoppingLists[i].items!.indexWhere((item) => item.id == itemId);
        if (idx != -1) {
          listIndex = i;
          itemIndex = idx;
          oldItem = _shoppingLists[i].items![idx];
          
          // Tạo item mới với isBought updated
          final updatedItem = ShoppingItem(
            id: oldItem.id,
            name: oldItem.name,
            quantity: oldItem.quantity,
            unit: oldItem.unit,
            note: oldItem.note,
            isBought: isBought,
            assignedTo: oldItem.assignedTo,
            boughtBy: oldItem.boughtBy,
            boughtAt: isBought ? DateTime.now() : null,
            productId: oldItem.productId,
            productImageUrl: oldItem.productImageUrl,
            version: oldItem.version,
          );
          
          final updatedItems = List<ShoppingItem>.from(_shoppingLists[i].items!);
          updatedItems[idx] = updatedItem;
          _shoppingLists[i] = ShoppingList(
            id: _shoppingLists[i].id,
            name: _shoppingLists[i].name,
            description: _shoppingLists[i].description,
            familyId: _shoppingLists[i].familyId,
            status: _shoppingLists[i].status,
            version: _shoppingLists[i].version,
            createdBy: _shoppingLists[i].createdBy,
            createdAt: _shoppingLists[i].createdAt,
            updatedAt: _shoppingLists[i].updatedAt,
            items: updatedItems,
            itemCount: _shoppingLists[i].itemCount,
            boughtCount: _shoppingLists[i].boughtCount != null 
                ? (isBought 
                    ? _shoppingLists[i].boughtCount! + (oldItem.isBought ? 0 : 1)
                    : _shoppingLists[i].boughtCount! - (oldItem.isBought ? 1 : 0))
                : null,
          );
          break;
        }
      }
    }
    
    // Cập nhật _currentShoppingList nếu có
    if (_currentShoppingList?.items != null) {
      final index = _currentShoppingList!.items!.indexWhere((item) => item.id == itemId);
      if (index != -1) {
        final oldCurrentItem = _currentShoppingList!.items![index];
        final updatedItem = ShoppingItem(
          id: oldCurrentItem.id,
          name: oldCurrentItem.name,
          quantity: oldCurrentItem.quantity,
          unit: oldCurrentItem.unit,
          note: oldCurrentItem.note,
          isBought: isBought,
          assignedTo: oldCurrentItem.assignedTo,
          boughtBy: oldCurrentItem.boughtBy,
          boughtAt: isBought ? DateTime.now() : null,
          productId: oldCurrentItem.productId,
          productImageUrl: oldCurrentItem.productImageUrl,
          version: oldCurrentItem.version,
        );
        
        final updatedItems = List<ShoppingItem>.from(_currentShoppingList!.items!);
        updatedItems[index] = updatedItem;
        _currentShoppingList = ShoppingList(
          id: _currentShoppingList!.id,
          name: _currentShoppingList!.name,
          description: _currentShoppingList!.description,
          familyId: _currentShoppingList!.familyId,
          status: _currentShoppingList!.status,
          version: _currentShoppingList!.version,
          createdBy: _currentShoppingList!.createdBy,
          createdAt: _currentShoppingList!.createdAt,
          updatedAt: DateTime.now(),
          items: updatedItems,
        );
      }
    }
    
    // Thông báo UI update ngay
    notifyListeners();
    
    // Lưu thông tin pending update
    if (oldItem != null && listIndex != null && itemIndex != null) {
      _pendingUpdates[itemId] = _PendingUpdate(
        isBought: isBought,
        version: version,
        oldItem: oldItem,
        listIndex: listIndex,
        itemIndex: itemIndex,
      );
    }
    
    // Tạo timer mới 3 giây
    _debounceTimers[itemId] = Timer(const Duration(seconds: 3), () async {
      await _performUpdate(itemId);
    });
  }
  
  // Thực hiện update thực sự sau khi debounce
  Future<void> _performUpdate(int itemId) async {
    final pending = _pendingUpdates[itemId];
    if (pending == null) return;
    
    _errorMessage = null;
    
    try {
      final updatedItem = await _apiService.updateShoppingItem(itemId, {
        'isBought': pending.isBought,
        'version': pending.version,
      });
      
      // Cập nhật lại với data từ server (có version mới)
      if (_shoppingLists.length > pending.listIndex && _shoppingLists[pending.listIndex].items != null) {
        final items = _shoppingLists[pending.listIndex].items!;
        if (items.length > pending.itemIndex) {
          final updatedItems = List<ShoppingItem>.from(items);
          updatedItems[pending.itemIndex] = updatedItem;
          _shoppingLists[pending.listIndex] = ShoppingList(
            id: _shoppingLists[pending.listIndex].id,
            name: _shoppingLists[pending.listIndex].name,
            description: _shoppingLists[pending.listIndex].description,
            familyId: _shoppingLists[pending.listIndex].familyId,
            status: _shoppingLists[pending.listIndex].status,
            version: _shoppingLists[pending.listIndex].version,
            createdBy: _shoppingLists[pending.listIndex].createdBy,
            createdAt: _shoppingLists[pending.listIndex].createdAt,
            updatedAt: _shoppingLists[pending.listIndex].updatedAt,
            items: updatedItems,
            itemCount: _shoppingLists[pending.listIndex].itemCount,
            boughtCount: _shoppingLists[pending.listIndex].boughtCount,
          );
        }
      }
      
      if (_currentShoppingList?.items != null) {
        final index = _currentShoppingList!.items!.indexWhere((item) => item.id == itemId);
        if (index != -1) {
          final updatedItems = List<ShoppingItem>.from(_currentShoppingList!.items!);
          updatedItems[index] = updatedItem;
          _currentShoppingList = ShoppingList(
            id: _currentShoppingList!.id,
            name: _currentShoppingList!.name,
            description: _currentShoppingList!.description,
            familyId: _currentShoppingList!.familyId,
            status: _currentShoppingList!.status,
            version: _currentShoppingList!.version,
            createdBy: _currentShoppingList!.createdBy,
            createdAt: _currentShoppingList!.createdAt,
            updatedAt: DateTime.now(),
            items: updatedItems,
          );
        }
      }
      
      // Xóa pending update
      _pendingUpdates.remove(itemId);
      _debounceTimers.remove(itemId);
      
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      
      // Rollback nếu API thất bại
      if (_shoppingLists.length > pending.listIndex && _shoppingLists[pending.listIndex].items != null) {
        final items = _shoppingLists[pending.listIndex].items!;
        if (items.length > pending.itemIndex) {
          final updatedItems = List<ShoppingItem>.from(items);
          updatedItems[pending.itemIndex] = pending.oldItem;
          _shoppingLists[pending.listIndex] = ShoppingList(
            id: _shoppingLists[pending.listIndex].id,
            name: _shoppingLists[pending.listIndex].name,
            description: _shoppingLists[pending.listIndex].description,
            familyId: _shoppingLists[pending.listIndex].familyId,
            status: _shoppingLists[pending.listIndex].status,
            version: _shoppingLists[pending.listIndex].version,
            createdBy: _shoppingLists[pending.listIndex].createdBy,
            createdAt: _shoppingLists[pending.listIndex].createdAt,
            updatedAt: _shoppingLists[pending.listIndex].updatedAt,
            items: updatedItems,
            itemCount: _shoppingLists[pending.listIndex].itemCount,
            boughtCount: _shoppingLists[pending.listIndex].boughtCount != null 
                ? (!pending.isBought 
                    ? _shoppingLists[pending.listIndex].boughtCount! + 1 
                    : _shoppingLists[pending.listIndex].boughtCount! - 1)
                : null,
          );
        }
      }
      
      // Rollback _currentShoppingList
      if (_currentShoppingList?.items != null) {
        final index = _currentShoppingList!.items!.indexWhere((item) => item.id == itemId);
        if (index != -1) {
          final updatedItems = List<ShoppingItem>.from(_currentShoppingList!.items!);
          updatedItems[index] = pending.oldItem;
          _currentShoppingList = ShoppingList(
            id: _currentShoppingList!.id,
            name: _currentShoppingList!.name,
            description: _currentShoppingList!.description,
            familyId: _currentShoppingList!.familyId,
            status: _currentShoppingList!.status,
            version: _currentShoppingList!.version,
            createdBy: _currentShoppingList!.createdBy,
            createdAt: _currentShoppingList!.createdAt,
            updatedAt: _currentShoppingList!.updatedAt,
            items: updatedItems,
          );
        }
      }
      
      _pendingUpdates.remove(itemId);
      _debounceTimers.remove(itemId);
      
      notifyListeners();
    }
  }

  // Delete an item from shopping list
  Future<void> deleteShoppingItem(int itemId) async {
    _errorMessage = null;
    try {
      await _apiService.deleteShoppingItem(itemId);
      if (_currentShoppingList?.items != null) {
        final updatedItems = _currentShoppingList!.items!.where((item) => item.id != itemId).toList();
        _currentShoppingList = ShoppingList(
          id: _currentShoppingList!.id,
          name: _currentShoppingList!.name,
          description: _currentShoppingList!.description,
          familyId: _currentShoppingList!.familyId,
          status: _currentShoppingList!.status,
          version: _currentShoppingList!.version,
          createdBy: _currentShoppingList!.createdBy,
          createdAt: _currentShoppingList!.createdAt,
          updatedAt: DateTime.now(),
          items: updatedItems,
        );
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  // Clear current shopping list
  void clearCurrentList() {
    _currentShoppingList = null;
    notifyListeners();
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

class _PendingUpdate {
  final bool isBought;
  final int version;
  final ShoppingItem oldItem;
  final int listIndex;
  final int itemIndex;

  _PendingUpdate({
    required this.isBought,
    required this.version,
    required this.oldItem,
    required this.listIndex,
    required this.itemIndex,
  });
}
