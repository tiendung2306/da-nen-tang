import 'package:flutter/material.dart';
import 'package:flutter_boilerplate/models/fridge_item.dart';
import 'package:flutter_boilerplate/providers/base_provider.dart';
import 'package:flutter_boilerplate/services/api/api_service.dart';
import 'package:flutter_boilerplate/services/locator.dart';

class FridgeProvider extends BaseProvider {
  final ApiService _apiService = locator<ApiService>();

  List<FridgeItem> _items = [];
  List<FridgeItem> get items => _items;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> fetchFridgeItems(int familyId) async {
    setStatus(ViewStatus.Loading);
    _errorMessage = null;
    try {
      _items = await _apiService.getFridgeItems(familyId);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      setStatus(ViewStatus.Ready);
    }
  }

  Future<void> addFridgeItem(Map<String, dynamic> itemData) async {
    // We don't set loading status here to avoid blocking the main list UI
    try {
      final newItem = await _apiService.addFridgeItem(itemData);
      // Add the new item returned from the backend (with its ID) to the list
      _items.insert(0, newItem);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
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
    }
  }
}
