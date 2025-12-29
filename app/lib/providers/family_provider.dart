import 'package:flutter/material.dart';
import 'package:flutter_boilerplate/models/family_model.dart';
import 'package:flutter_boilerplate/providers/base_provider.dart';
import 'package:flutter_boilerplate/services/api/api_service.dart';
import 'package:flutter_boilerplate/services/locator.dart';

class FamilyProvider extends BaseProvider {
  final ApiService _apiService = locator<ApiService>();

  List<Family> _families = [];
  List<Family> get families => _families;

  Family? _selectedFamily;
  Family? get selectedFamily => _selectedFamily;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> fetchFamilies() async {
    setStatus(ViewStatus.Loading);
    _errorMessage = null;
    try {
      _families = await _apiService.getFamilies();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      setStatus(ViewStatus.Ready);
    }
  }

  Future<void> selectFamily(int familyId) async {
    // ... (implementation remains the same)
  }

  /// Creates a new family and then refetches the list of families.
  Future<void> createFamily(Map<String, dynamic> familyData) async {
    // We can set a specific status for this action if needed
    // setStatus(ViewStatus.Loading);
    try {
      final newFamily = await _apiService.createFamily(familyData);
      // To update the UI, we can either add the new family to the list locally,
      // or simply refetch the entire list.
      await fetchFamilies();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners(); // Notify listeners to show the error
    }
    // setStatus(ViewStatus.Ready);
  }
}
