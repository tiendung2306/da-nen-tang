import 'package:dio/dio.dart';
import 'package:flutter_boilerplate/constants/api_config.dart';
import 'package:flutter_boilerplate/models/auth_model.dart';
import 'package:flutter_boilerplate/models/family_model.dart';
import 'package:flutter_boilerplate/models/friend_model.dart';
import 'package:flutter_boilerplate/models/fridge_item.dart';
import 'package:flutter_boilerplate/models/recipe_model.dart';
import 'package:flutter_boilerplate/services/shared_pref/shared_pref.dart';

class ApiService {
  final Dio _dio;

  // --- Setup ---
  ApiService._() : _dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl)) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await SharedPref.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) => handler.next(e),
    ));
    _dio.interceptors.add(LogInterceptor(responseBody: true, requestBody: true, requestHeader: true));
  }

  static final ApiService _instance = ApiService._();
  factory ApiService() => _instance;

  Exception _handleDioError(DioException e) {
    if (e.response?.data != null && e.response!.data is Map) {
      return Exception(e.response!.data['message'] ?? 'An unknown API error occurred');
    }
    return Exception('Failed to connect to the server.');
  }

  // --- Auth & User ---
  Future<LoginData> login({required String username, required String password, String? deviceToken}) async {
    try {
      final response = await _dio.post(ApiConfig.login, data: {'username': username, 'password': password, if (deviceToken != null) 'device_token': deviceToken});
      return LoginData.fromJson(response.data['data']);
    } on DioException catch (e) { throw _handleDioError(e); }
  }

  Future<List<UserInfo>> searchUsers(String query) async {
    try {
      final response = await _dio.get(ApiConfig.userSearch, queryParameters: {'keyword': query});
      final paginatedData = response.data['data'];
      if (paginatedData != null && paginatedData['content'] is List) {
        return (paginatedData['content'] as List).map((i) => UserInfo.fromJson(i)).toList();
      }
      return [];
    } on DioException catch (e) { throw _handleDioError(e); }
  }

  // --- Friend APIs ---
  Future<List<UserInfo>> getFriends() async {
    try {
      final response = await _dio.get(ApiConfig.friends);
      return (response.data['data'] as List).map((i) => UserInfo.fromJson(i)).toList();
    } on DioException catch (e) { throw _handleDioError(e); }
  }

  Future<List<FriendRequest>> getReceivedFriendRequests() async {
    try {
      final response = await _dio.get(ApiConfig.receivedFriendRequests);
      return (response.data['data'] as List).map((i) => FriendRequest.fromJson(i)).toList();
    } on DioException catch (e) { throw _handleDioError(e); }
  }

  Future<List<FriendRequest>> getSentFriendRequests() async {
    try {
      final response = await _dio.get(ApiConfig.sentFriendRequests);
      return (response.data['data'] as List).map((i) => FriendRequest.fromJson(i)).toList();
    } on DioException catch (e) { throw _handleDioError(e); }
  }

  Future<void> sendFriendRequest({required String userId}) async {
    try {
      await _dio.post(ApiConfig.friendRequests, data: {'userId': userId});
    } on DioException catch (e) { throw _handleDioError(e); }
  }

  Future<void> respondToFriendRequest({required String requestId, required bool accept}) async {
    try {
      await _dio.post(ApiConfig.respondToFriendRequest(requestId), data: {'response': accept ? 'accept' : 'decline'});
    } on DioException catch (e) { throw _handleDioError(e); }
  }

  Future<void> cancelFriendRequest({required String requestId}) async {
    try {
      await _dio.delete(ApiConfig.cancelFriendRequest(requestId));
    } on DioException catch (e) { throw _handleDioError(e); }
  }

  Future<void> unfriend({required String userId}) async {
    try {
      await _dio.delete(ApiConfig.unfriend(userId));
    } on DioException catch (e) { throw _handleDioError(e); }
  }

  Future<FriendStatusResponse> getFriendStatus({required String userId}) async {
    try {
      final response = await _dio.get(ApiConfig.friendStatus(userId));
      return FriendStatusResponse.fromJson(response.data['data']);
    } on DioException catch (e) { throw _handleDioError(e); }
  }

  // --- Family APIs ---
  Future<List<Family>> getFamilies() async {
    try {
      final response = await _dio.get(ApiConfig.families);
      return (response.data['data'] as List).map((i) => Family.fromJson(i)).toList();
    } on DioException catch (e) { throw _handleDioError(e); }
  }

  Future<Family> createFamily(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(ApiConfig.families, data: data);
      return Family.fromJson(response.data['data']);
    } on DioException catch (e) { throw _handleDioError(e); }
  }

  // --- Fridge APIs ---
  Future<List<FridgeItem>> getFridgeItems(int familyId) async {
    try {
      final response = await _dio.get(ApiConfig.familyFridgeItems(familyId));
      return (response.data['data'] as List).map((i) => FridgeItem.fromJson(i)).toList();
    } on DioException catch (e) { throw _handleDioError(e); }
  }

  Future<FridgeItem> addFridgeItem(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(ApiConfig.fridgeItems, data: data);
      return FridgeItem.fromJson(response.data['data']);
    } on DioException catch (e) { throw _handleDioError(e); }
  }

  Future<void> deleteFridgeItem(int itemId) async {
    try {
      await _dio.delete(ApiConfig.fridgeItemById(itemId));
    } on DioException catch (e) { throw _handleDioError(e); }
  }

  // --- Recipe APIs ---
  Future<List<Recipe>> getRecipes({int page = 0, int size = 10}) async {
    try {
      final response = await _dio.get(ApiConfig.recipes, queryParameters: {'page': page, 'size': size});
      final paginatedData = response.data['data'];
      if (paginatedData != null && paginatedData['content'] is List) {
        return (paginatedData['content'] as List).map((i) => Recipe.fromJson(i)).toList();
      }
      return [];
    } on DioException catch (e) { throw _handleDioError(e); }
  }

  Future<Recipe> getRecipeById(int id) async {
    try {
      final response = await _dio.get(ApiConfig.recipeById(id));
      return Recipe.fromJson(response.data['data']);
    } on DioException catch (e) { throw _handleDioError(e); }
  }

  Future<List<Recipe>> searchRecipes(String title) async {
    try {
      final response = await _dio.get(ApiConfig.searchRecipes, queryParameters: {'title': title});
      final paginatedData = response.data['data'];
      if (paginatedData != null && paginatedData['content'] is List) {
        return (paginatedData['content'] as List).map((i) => Recipe.fromJson(i)).toList();
      }
      return [];
    } on DioException catch (e) { throw _handleDioError(e); }
  }

  Future<Recipe> createRecipe(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(ApiConfig.recipes, data: data);
      return Recipe.fromJson(response.data['data']);
    } on DioException catch (e) { throw _handleDioError(e); }
  }

  Future<Recipe> updateRecipe(int id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put(ApiConfig.recipeById(id), data: data);
      return Recipe.fromJson(response.data['data']);
    } on DioException catch (e) { throw _handleDioError(e); }
  }

  Future<void> deleteRecipe(int id) async {
    try {
      await _dio.delete(ApiConfig.recipeById(id));
    } on DioException catch (e) { throw _handleDioError(e); }
  }
}
