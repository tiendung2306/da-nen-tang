import 'package:flutter/material.dart';
import 'package:flutter_boilerplate/models/recipe_model.dart';
import 'package:flutter_boilerplate/providers/base_provider.dart';
import 'package:flutter_boilerplate/services/api/api_service.dart';
import 'package:flutter_boilerplate/services/locator.dart';

class RecipeProvider extends BaseProvider {
  final ApiService _apiService = locator<ApiService>();

  List<Recipe> _recipes = [];
  Recipe? _selectedRecipe;
  int _currentPage = 0;
  bool _isLoadingMore = false;
  bool _hasMore = true;

  List<Recipe> get recipes => _recipes;
  Recipe? get selectedRecipe => _selectedRecipe;
  bool get isLoadingMore => _isLoadingMore;

  Future<void> fetchRecipes({bool isRefresh = false}) async {
    if (isRefresh) {
      _currentPage = 0;
      _recipes = [];
      _hasMore = true;
    }
    setStatus(ViewStatus.Loading);
    try {
      final newRecipes = await _apiService.getRecipes(page: _currentPage);
      if (newRecipes.isEmpty) {
        _hasMore = false;
      } else {
        _recipes.addAll(newRecipes);
        _currentPage++;
      }
    } finally {
      setStatus(ViewStatus.Ready);
    }
  }

  Future<void> fetchMoreRecipes() async {
    if (_isLoadingMore || !_hasMore) return;
    _isLoadingMore = true;
    notifyListeners();
    try {
      final newRecipes = await _apiService.getRecipes(page: _currentPage);
      if (newRecipes.isEmpty) {
        _hasMore = false;
      } else {
        _recipes.addAll(newRecipes);
        _currentPage++;
      }
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> fetchRecipeById(int id) async {
    setStatus(ViewStatus.Loading);
    try {
      _selectedRecipe = await _apiService.getRecipeById(id);
    } finally {
      setStatus(ViewStatus.Ready);
    }
  }

  // FIX: Implemented Optimistic Update
  Future<void> createRecipe(Map<String, dynamic> data) async {
    // The API call itself returns the newly created recipe.
    final newRecipe = await _apiService.createRecipe(data);
    
    // Instead of re-fetching the whole list, just add the new recipe to the top.
    _recipes.insert(0, newRecipe);
    
    // Notify listeners to update the UI with the new list.
    notifyListeners();
  }

  Future<void> deleteRecipe(int id) async {
    await _apiService.deleteRecipe(id);
    _recipes.removeWhere((recipe) => recipe.id == id);
    notifyListeners();
  }
}
