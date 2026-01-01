import 'package:flutter/material.dart';
import 'package:flutter_boilerplate/models/shopping_list_model.dart';
import 'package:flutter_boilerplate/providers/base_provider.dart';
import 'package:flutter_boilerplate/services/api/api_service.dart';
import 'package:flutter_boilerplate/services/locator.dart';

class ShoppingListProvider extends BaseProvider {
  final ApiService _apiService = locator<ApiService>();

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
    List<CreateShoppingItemRequest>? items,
  }) async {
    _errorMessage = null;
    try {
      final data = {
        'familyId': familyId,
        'name': name,
        if (description != null) 'description': description,
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

  // Update shopping list status
  Future<void> updateShoppingListStatus(int listId, ShoppingListStatus status, {required int version}) async {
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
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
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

  // Toggle item bought status
  Future<void> toggleItemBought(int itemId, bool isBought, {int? version}) async {
    _errorMessage = null;
    try {
      final updatedItem = await _apiService.updateShoppingItem(itemId, {
        'isBought': isBought,
        if (version != null) 'version': version,
      });
      
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
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
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
