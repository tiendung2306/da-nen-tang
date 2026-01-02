import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_boilerplate/services/api/api_service.dart';
import 'package:flutter_boilerplate/services/locator.dart';

/// Service to generate AI-powered recipe suggestions via backend proxy
/// This ensures API key security and proper rate limiting
class FireworksAIService {
  final ApiService _apiService = locator<ApiService>();

  /// Generate recipe suggestions based on available ingredients from fridge
  /// Calls backend API which proxies to Fireworks AI
  Future<Map<String, dynamic>> generateRecipeSuggestion({
    required List<String> availableIngredients,
    String? dietaryPreference,
    String? cuisineType,
    int? servings,
  }) async {
    try {
      final data = await _apiService.generateAIRecipeSuggestion(
        availableIngredients: availableIngredients,
        dietaryPreference: dietaryPreference,
        cuisineType: cuisineType,
        servings: servings,
      );
      return _parseRecipeResponse(data);
    } catch (e) {
      rethrow;
    }
  }

  /// Check remaining AI requests for current user
  Future<Map<String, dynamic>> checkRateLimit() async {
    try {
      return await _apiService.checkAIRateLimit();
    } catch (e) {
      rethrow;
    }
  }

  Map<String, dynamic> _parseRecipeResponse(dynamic data) {
    try {
      // Backend already returns parsed JSON
      final recipe = data as Map<String, dynamic>;
      
      // Validate required fields
      if (!recipe.containsKey('title') || 
          !recipe.containsKey('description') ||
          !recipe.containsKey('ingredients') ||
          !recipe.containsKey('instructions')) {
        throw Exception('Response missing required fields');
      }

      return recipe;
    } catch (e) {
      throw Exception('Không thể phân tích phản hồi: $e');
    }
  }
}
