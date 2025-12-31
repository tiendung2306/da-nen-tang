import 'package:flutter/material.dart';
import 'package:flutter_boilerplate/models/meal_plan_model.dart';
import 'package:flutter_boilerplate/providers/base_provider.dart';
import 'package:flutter_boilerplate/services/api/api_service.dart';
import 'package:flutter_boilerplate/services/locator.dart';
import 'package:intl/intl.dart';

class MealPlanProvider extends BaseProvider {
  final ApiService _apiService = locator<ApiService>();

  List<MealPlan> _mealPlans = [];
  List<MealPlan> get mealPlans => _mealPlans;

  MealPlan? _currentMealPlan;
  MealPlan? get currentMealPlan => _currentMealPlan;

  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Helper to format date for API
  String _formatDate(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  // Set selected date
  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  // Fetch meal plans for a date range
  Future<void> fetchMealPlans(int familyId, {DateTime? startDate, DateTime? endDate}) async {
    setStatus(ViewStatus.Loading);
    _errorMessage = null;
    try {
      _mealPlans = await _apiService.getMealPlans(
        familyId,
        startDate: startDate != null ? _formatDate(startDate) : null,
        endDate: endDate != null ? _formatDate(endDate) : null,
      );
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      setStatus(ViewStatus.Ready);
    }
  }

  // Fetch daily meal plans
  Future<void> fetchDailyMealPlans(int familyId, DateTime date) async {
    setStatus(ViewStatus.Loading);
    _errorMessage = null;
    _selectedDate = date;
    try {
      _mealPlans = await _apiService.getDailyMealPlans(familyId, _formatDate(date));
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      setStatus(ViewStatus.Ready);
    }
  }

  // Fetch weekly meal plans
  Future<void> fetchWeeklyMealPlans(int familyId, DateTime startDate) async {
    setStatus(ViewStatus.Loading);
    _errorMessage = null;
    try {
      _mealPlans = await _apiService.getWeeklyMealPlans(familyId, _formatDate(startDate));
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      setStatus(ViewStatus.Ready);
    }
  }

  // Get meal plan by ID
  Future<void> fetchMealPlanDetails(int mealPlanId) async {
    setStatus(ViewStatus.Loading);
    _errorMessage = null;
    try {
      _currentMealPlan = await _apiService.getMealPlanById(mealPlanId);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      setStatus(ViewStatus.Ready);
    }
  }

  // Create a new meal plan
  Future<MealPlan?> createMealPlan({
    required int familyId,
    required DateTime date,
    required MealType mealType,
    String? note,
    List<CreateMealItemRequest>? items,
  }) async {
    _errorMessage = null;
    try {
      final data = {
        'familyId': familyId,
        'date': _formatDate(date),
        'mealType': mealType.name,
        if (note != null) 'note': note,
        if (items != null) 'items': items.map((e) => e.toJson()).toList(),
      };
      final newPlan = await _apiService.createMealPlan(data);
      _mealPlans.add(newPlan);
      notifyListeners();
      return newPlan;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  // Update meal plan
  Future<void> updateMealPlan(int mealPlanId, {String? note}) async {
    _errorMessage = null;
    try {
      final data = <String, dynamic>{};
      if (note != null) data['note'] = note;
      
      final updatedPlan = await _apiService.updateMealPlan(mealPlanId, data);
      final index = _mealPlans.indexWhere((plan) => plan.id == mealPlanId);
      if (index != -1) {
        _mealPlans[index] = updatedPlan;
      }
      if (_currentMealPlan?.id == mealPlanId) {
        _currentMealPlan = updatedPlan;
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  // Delete meal plan
  Future<bool> deleteMealPlan(int mealPlanId) async {
    _errorMessage = null;
    try {
      await _apiService.deleteMealPlan(mealPlanId);
      _mealPlans.removeWhere((plan) => plan.id == mealPlanId);
      if (_currentMealPlan?.id == mealPlanId) {
        _currentMealPlan = null;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // Add meal item to a meal plan
  Future<void> addMealItem(int mealPlanId, CreateMealItemRequest item) async {
    _errorMessage = null;
    try {
      final newItem = await _apiService.addMealItem(mealPlanId, item.toJson());
      
      // Update the meal plan in the list
      final index = _mealPlans.indexWhere((plan) => plan.id == mealPlanId);
      if (index != -1) {
        final plan = _mealPlans[index];
        final updatedItems = [...?plan.items, newItem];
        _mealPlans[index] = MealPlan(
          id: plan.id,
          familyId: plan.familyId,
          date: plan.date,
          mealType: plan.mealType,
          note: plan.note,
          createdBy: plan.createdBy,
          createdAt: plan.createdAt,
          updatedAt: DateTime.now(),
          items: updatedItems,
        );
      }
      
      // Update current meal plan if viewing
      if (_currentMealPlan?.id == mealPlanId) {
        final updatedItems = [...?_currentMealPlan!.items, newItem];
        _currentMealPlan = MealPlan(
          id: _currentMealPlan!.id,
          familyId: _currentMealPlan!.familyId,
          date: _currentMealPlan!.date,
          mealType: _currentMealPlan!.mealType,
          note: _currentMealPlan!.note,
          createdBy: _currentMealPlan!.createdBy,
          createdAt: _currentMealPlan!.createdAt,
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

  // Delete meal item
  Future<void> deleteMealItem(int itemId, int mealPlanId) async {
    _errorMessage = null;
    try {
      await _apiService.deleteMealItem(itemId);
      
      // Update the meal plan in the list
      final index = _mealPlans.indexWhere((plan) => plan.id == mealPlanId);
      if (index != -1) {
        final plan = _mealPlans[index];
        final updatedItems = plan.items?.where((item) => item.id != itemId).toList();
        _mealPlans[index] = MealPlan(
          id: plan.id,
          familyId: plan.familyId,
          date: plan.date,
          mealType: plan.mealType,
          note: plan.note,
          createdBy: plan.createdBy,
          createdAt: plan.createdAt,
          updatedAt: DateTime.now(),
          items: updatedItems,
        );
      }
      
      // Update current meal plan if viewing
      if (_currentMealPlan?.id == mealPlanId) {
        final updatedItems = _currentMealPlan!.items?.where((item) => item.id != itemId).toList();
        _currentMealPlan = MealPlan(
          id: _currentMealPlan!.id,
          familyId: _currentMealPlan!.familyId,
          date: _currentMealPlan!.date,
          mealType: _currentMealPlan!.mealType,
          note: _currentMealPlan!.note,
          createdBy: _currentMealPlan!.createdBy,
          createdAt: _currentMealPlan!.createdAt,
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

  // Get meal plans by type for a specific date
  List<MealPlan> getMealPlansByType(MealType type) {
    return _mealPlans.where((plan) => plan.mealType == type).toList();
  }

  // Get meal plan for a specific meal type on selected date
  MealPlan? getMealPlanForType(MealType type) {
    try {
      return _mealPlans.firstWhere(
        (plan) => plan.mealType == type && 
                  plan.date.year == _selectedDate.year &&
                  plan.date.month == _selectedDate.month &&
                  plan.date.day == _selectedDate.day,
      );
    } catch (e) {
      return null;
    }
  }

  // Clear current meal plan
  void clearCurrentPlan() {
    _currentMealPlan = null;
    notifyListeners();
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
