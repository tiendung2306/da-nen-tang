import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_boilerplate/constants/api_config.dart';
import 'package:flutter_boilerplate/models/auth_model.dart';
import 'package:flutter_boilerplate/models/family_model.dart';
import 'package:flutter_boilerplate/models/family_invitation_model.dart';
import 'package:flutter_boilerplate/models/friend_model.dart';
import 'package:flutter_boilerplate/models/fridge_item.dart';
import 'package:flutter_boilerplate/models/fridge_statistics.dart';
import 'package:flutter_boilerplate/models/meal_plan_model.dart';
import 'package:flutter_boilerplate/models/notification_model.dart';
import 'package:flutter_boilerplate/models/product_model.dart';
import 'package:flutter_boilerplate/models/recipe_model.dart';
import 'package:flutter_boilerplate/models/shopping_list_model.dart';
import 'package:flutter_boilerplate/services/shared_pref/shared_pref.dart';

class ApiService {
  final Dio _dio;

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
    _dio.interceptors.add(LogInterceptor(
        responseBody: true, requestBody: true, requestHeader: true));
  }

  static final ApiService _instance = ApiService._();
  factory ApiService() => _instance;

  Exception _handleDioError(DioException e) {
    if (e.response?.data != null && e.response!.data is Map) {
      return Exception(
          e.response!.data['message'] ?? 'An unknown API error occurred');
    }
    return Exception('Failed to connect to the server.');
  }

  // --- Auth & User ---
  Future<void> register({
    required String fullName,
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      await _dio.post(ApiConfig.register, data: {
        'fullName': fullName,
        'username': username,
        'email': email,
        'password': password,
      });
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<LoginData> login(
      {required String username,
      required String password,
      String? deviceToken}) async {
    try {
      final response = await _dio.post(ApiConfig.login, data: {
        'username': username,
        'password': password,
        if (deviceToken != null) 'device_token': deviceToken,
      });
      return LoginData.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<UserInfo> getCurrentUser() async {
    try {
      final response = await _dio.get(ApiConfig.me);
      return UserInfo.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<UserInfo> uploadUserAvatar(XFile image) async {
    try {
      final bytes = await image.readAsBytes();
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: image.name),
      });
      final response = await _dio.post(
        ApiConfig.userAvatar,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return UserInfo.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<UserInfo> deleteUserAvatar() async {
    try {
      final response = await _dio.delete(ApiConfig.userAvatar);
      return UserInfo.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<List<UserInfo>> searchUsers(String query) async {
    try {
      final response = await _dio
          .get(ApiConfig.userSearch, queryParameters: {'keyword': query});
      final paginatedData = response.data['data'];
      if (paginatedData != null && paginatedData['content'] is List) {
        return (paginatedData['content'] as List)
            .map((i) => UserInfo.fromJson(i))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // --- Friend APIs ---
  Future<List<UserInfo>> getFriends() async {
    try {
      final response = await _dio.get(ApiConfig.friends);
      final data = response.data['data'];
      if (data == null) return [];
      return (data as List).map((i) => UserInfo.fromJson(i)).toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<List<FriendRequest>> getReceivedFriendRequests() async {
    try {
      final response = await _dio.get(ApiConfig.receivedFriendRequests);
      final data = response.data['data'];
      if (data == null) return [];
      return (data as List).map((i) => FriendRequest.fromJson(i)).toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<List<FriendRequest>> getSentFriendRequests() async {
    try {
      final response = await _dio.get(ApiConfig.sentFriendRequests);
      final data = response.data['data'];
      if (data == null) return [];
      return (data as List).map((i) => FriendRequest.fromJson(i)).toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> sendFriendRequest({required String userId}) async {
    try {
      await _dio.post(ApiConfig.friendRequests, data: {'userId': userId});
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> respondToFriendRequest(
      {required String requestId, required bool accept}) async {
    try {
      await _dio.post(ApiConfig.respondToFriendRequest(requestId),
          data: {'accept': accept});
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> cancelFriendRequest({required String requestId}) async {
    try {
      await _dio.delete(ApiConfig.cancelFriendRequest(requestId));
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> unfriend({required String userId}) async {
    try {
      await _dio.delete(ApiConfig.unfriend(userId));
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<FriendStatusResponse> getFriendStatus({required String userId}) async {
    try {
      final response = await _dio.get(ApiConfig.friendStatus(userId));
      return FriendStatusResponse.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // --- Family APIs ---
  Future<List<Family>> getFamilies() async {
    try {
      final response = await _dio.get(ApiConfig.families);
      final data = response.data['data'];
      if (data == null) return [];
      return (data as List).map((i) => Family.fromJson(i)).toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Family> getFamilyById(int id) async {
    try {
      final response = await _dio.get(ApiConfig.familyById(id));
      return Family.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Family> createFamily(Map<String, dynamic> data, {XFile? image}) async {
    try {
      final Map<String, dynamic> formMap = {
        'name': data['name'],
        if (data['description'] != null) 'description': data['description'],
        if (data['friendIds'] != null && (data['friendIds'] as List).isNotEmpty)
          'friendIds':
              (data['friendIds'] as List).map((id) => id.toString()).toList(),
      };

      if (image != null) {
        final bytes = await image.readAsBytes();
        formMap['image'] = MultipartFile.fromBytes(bytes, filename: image.name);
      }

      final formData = FormData.fromMap(formMap);
      final response = await _dio.post(
        ApiConfig.families,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return Family.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Family> updateFamilyWithImage(int id, Map<String, dynamic> data,
      {XFile? image}) async {
    try {
      final Map<String, dynamic> formMap = {
        if (data['name'] != null) 'name': data['name'],
        if (data['description'] != null) 'description': data['description'],
      };

      if (image != null) {
        final bytes = await image.readAsBytes();
        formMap['image'] = MultipartFile.fromBytes(bytes, filename: image.name);
      }

      final formData = FormData.fromMap(formMap);
      final response = await _dio.put(
        ApiConfig.familyById(id),
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return Family.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Family> updateFamily(int id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put(ApiConfig.familyById(id), data: data);
      return Family.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> deleteFamily(int id) async {
    try {
      await _dio.delete(ApiConfig.familyById(id));
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Family> deleteFamilyImage(int familyId) async {
    try {
      final response = await _dio.delete(ApiConfig.familyImage(familyId));
      return Family.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<List<FamilyMember>> getFamilyMembers(int familyId) async {
    try {
      final response = await _dio.get(ApiConfig.familyMembers(familyId));
      final data = response.data['data'];
      if (data == null) return [];
      return (data as List).map((i) => FamilyMember.fromJson(i)).toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Family> joinFamily(String inviteCode) async {
    try {
      final response = await _dio
          .post(ApiConfig.joinFamily, data: {'inviteCode': inviteCode});
      return Family.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> leaveFamily(int familyId) async {
    try {
      await _dio.post(ApiConfig.leaveFamily(familyId));
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<String> generateInviteCode(int familyId) async {
    try {
      final response = await _dio.get(ApiConfig.familyById(familyId));
      return response.data['data']['inviteCode'] ?? '';
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<String> regenerateInviteCode(int familyId) async {
    try {
      final response =
          await _dio.post(ApiConfig.regenerateInviteCode(familyId));
      return response.data['data']['inviteCode'] ?? '';
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> inviteFriendToFamily(int familyId, int friendId) async {
    try {
      await _dio.post(ApiConfig.inviteFriendToFamily(familyId, friendId));
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // --- Family Invitation APIs ---
  Future<List<FamilyInvitation>> getFamilyInvitations() async {
    try {
      final response = await _dio.get(ApiConfig.familyInvitations);
      final data = response.data['data'];
      if (data == null) return [];
      return (data as List).map((i) => FamilyInvitation.fromJson(i)).toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> respondToFamilyInvitation(int invitationId, bool accept) async {
    try {
      await _dio.post(ApiConfig.respondToFamilyInvitation(invitationId),
          data: {'accept': accept});
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // --- Fridge APIs ---
  Future<List<FridgeItem>> getFridgeItems(int familyId,
      {int page = 0, int size = 20}) async {
    try {
      final response = await _dio.get(
        ApiConfig.familyFridgeItems(familyId),
        queryParameters: {'page': page, 'size': size},
      );
      final paginatedData = response.data['data'];
      if (paginatedData != null && paginatedData['content'] is List) {
        return (paginatedData['content'] as List)
            .map((i) => FridgeItem.fromJson(i))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<FridgeItem> addFridgeItem(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(ApiConfig.fridgeItems, data: data);
      return FridgeItem.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> deleteFridgeItem(int itemId) async {
    try {
      await _dio.delete(ApiConfig.fridgeItemById(itemId));
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<FridgeItem> updateFridgeItem(
      int itemId, Map<String, dynamic> data) async {
    try {
      final response =
          await _dio.patch(ApiConfig.fridgeItemById(itemId), data: data);
      return FridgeItem.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<List<FridgeItem>> getActiveFridgeItems(int familyId,
      {int page = 0, int size = 20}) async {
    try {
      final response = await _dio.get(
        ApiConfig.activeFridgeItems(familyId),
        queryParameters: {'page': page, 'size': size},
      );
      final paginatedData = response.data['data'];
      if (paginatedData != null && paginatedData['content'] is List) {
        return (paginatedData['content'] as List)
            .map((i) => FridgeItem.fromJson(i))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<List<FridgeItem>> getExpiringFridgeItems(int familyId,
      {int page = 0, int size = 20}) async {
    try {
      final response = await _dio.get(
        ApiConfig.expiringFridgeItems(familyId),
        queryParameters: {'page': page, 'size': size},
      );
      final paginatedData = response.data['data'];
      if (paginatedData != null && paginatedData['content'] is List) {
        return (paginatedData['content'] as List)
            .map((i) => FridgeItem.fromJson(i))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<List<FridgeItem>> getExpiredFridgeItems(int familyId,
      {int page = 0, int size = 20}) async {
    try {
      final response = await _dio.get(
        ApiConfig.expiredFridgeItems(familyId),
        queryParameters: {'page': page, 'size': size},
      );
      final paginatedData = response.data['data'];
      if (paginatedData != null && paginatedData['content'] is List) {
        return (paginatedData['content'] as List)
            .map((i) => FridgeItem.fromJson(i))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<FridgeStatistics> getFridgeStatistics(int familyId) async {
    try {
      final response = await _dio.get(ApiConfig.fridgeStatistics(familyId));
      return FridgeStatistics.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<FridgeItem> consumeFridgeItem(int itemId,
      {double? quantityUsed}) async {
    try {
      final response = await _dio.post(
        ApiConfig.consumeFridgeItem(itemId),
        data: quantityUsed != null ? {'quantityUsed': quantityUsed} : null,
      );
      return FridgeItem.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<FridgeItem> discardFridgeItem(int itemId) async {
    try {
      final response = await _dio.post(ApiConfig.discardFridgeItem(itemId));
      return FridgeItem.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // --- Recipe APIs ---
  Future<List<Recipe>> getRecipes({int page = 0, int size = 10}) async {
    try {
      final response = await _dio.get(ApiConfig.recipes,
          queryParameters: {'page': page, 'size': size});
      final paginatedData = response.data['data'];
      if (paginatedData != null && paginatedData['content'] is List) {
        return (paginatedData['content'] as List)
            .map((i) => Recipe.fromJson(i))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<RecipeDetail> getRecipeById(int id) async {
    try {
      final response = await _dio.get(ApiConfig.recipeById(id));
      return RecipeDetail.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<List<Recipe>> searchRecipes(String title) async {
    try {
      final response = await _dio
          .get(ApiConfig.searchRecipes, queryParameters: {'title': title});
      final paginatedData = response.data['data'];
      if (paginatedData != null && paginatedData['content'] is List) {
        return (paginatedData['content'] as List)
            .map((i) => Recipe.fromJson(i))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Recipe> createRecipe(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(ApiConfig.recipes, data: data);
      return Recipe.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Recipe> updateRecipe(int id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put(ApiConfig.recipeById(id), data: data);
      return Recipe.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> deleteRecipe(int id) async {
    try {
      await _dio.delete(ApiConfig.recipeById(id));
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // --- Shopping List APIs ---
  Future<List<ShoppingList>> getShoppingLists(int familyId) async {
    try {
      final response = await _dio.get(ApiConfig.familyShoppingLists(familyId));
      final data = response.data['data'];
      if (data == null) return [];
      // Handle paginated response (PageResponse with 'content' field)
      if (data is Map && data['content'] != null) {
        return (data['content'] as List)
            .map((i) => ShoppingList.fromJson(i))
            .toList();
      }
      // Handle direct list response
      if (data is List) {
        return data.map((i) => ShoppingList.fromJson(i)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<List<ShoppingList>> getActiveShoppingLists(int familyId) async {
    try {
      final response =
          await _dio.get(ApiConfig.familyActiveShoppingLists(familyId));
      final data = response.data['data'];
      if (data == null) return [];
      // Handle paginated response (PageResponse with 'content' field)
      if (data is Map && data['content'] != null) {
        return (data['content'] as List)
            .map((i) => ShoppingList.fromJson(i))
            .toList();
      }
      // Handle direct list response
      if (data is List) {
        return data.map((i) => ShoppingList.fromJson(i)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<ShoppingList> getShoppingListById(int id) async {
    try {
      final response = await _dio.get(ApiConfig.shoppingListById(id));
      return ShoppingList.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<ShoppingList> createShoppingList(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(ApiConfig.shoppingLists, data: data);
      return ShoppingList.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<ShoppingList> updateShoppingList(
      int id, Map<String, dynamic> data) async {
    try {
      final response =
          await _dio.patch(ApiConfig.shoppingListById(id), data: data);
      return ShoppingList.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> deleteShoppingList(int id) async {
    try {
      await _dio.delete(ApiConfig.shoppingListById(id));
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<ShoppingItem> addShoppingItem(
      int listId, Map<String, dynamic> data) async {
    try {
      final response =
          await _dio.post(ApiConfig.shoppingListItems(listId), data: data);
      return ShoppingItem.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<List<ShoppingItem>> addShoppingItemsBulk(
      int listId, List<Map<String, dynamic>> items) async {
    try {
      final response = await _dio.post(ApiConfig.shoppingListItemsBulk(listId),
          data: {'items': items});
      final data = response.data['data'];
      if (data == null) return [];
      return (data as List).map((i) => ShoppingItem.fromJson(i)).toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<ShoppingItem> updateShoppingItem(
      int itemId, Map<String, dynamic> data) async {
    try {
      final response =
          await _dio.patch(ApiConfig.shoppingItemById(itemId), data: data);
      return ShoppingItem.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> deleteShoppingItem(int itemId) async {
    try {
      await _dio.delete(ApiConfig.shoppingItemById(itemId));
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // --- Meal Plan APIs ---
  Future<List<MealPlan>> getMealPlans(int familyId,
      {String? startDate, String? endDate}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;
      final response = await _dio.get(ApiConfig.familyMealPlans(familyId),
          queryParameters: queryParams);
      final data = response.data['data'];
      if (data == null) return [];
      return (data as List).map((i) => MealPlan.fromJson(i)).toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<List<MealPlan>> getDailyMealPlans(int familyId, String date) async {
    try {
      final response = await _dio.get(ApiConfig.familyDailyMealPlans(familyId),
          queryParameters: {'date': date});
      final data = response.data['data'];
      if (data == null) return [];

      // Backend returns DailyMealPlanResponse (object with breakfast, lunch, dinner, snack)
      // Convert to List<MealPlan>
      final dailyPlan = DailyMealPlans.fromJson(data);
      return dailyPlan.mealPlans;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<List<MealPlan>> getWeeklyMealPlans(
      int familyId, String startDate) async {
    try {
      final response = await _dio.get(ApiConfig.familyWeeklyMealPlans(familyId),
          queryParameters: {'startDate': startDate});
      final data = response.data['data'];
      if (data == null) return [];

      // Backend returns WeeklyMealPlanResponse (object with days array)
      // Convert to flat List<MealPlan>
      final weeklyPlan = WeeklyMealPlans.fromJson(data);
      final allMealPlans = <MealPlan>[];
      for (final day in weeklyPlan.days) {
        allMealPlans.addAll(day.mealPlans);
      }
      return allMealPlans;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<MealPlan> getMealPlanById(int id) async {
    try {
      final response = await _dio.get(ApiConfig.mealPlanById(id));
      return MealPlan.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<MealPlan> createMealPlan(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(ApiConfig.mealPlans, data: data);
      return MealPlan.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<MealPlan> updateMealPlan(int id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put(ApiConfig.mealPlanById(id), data: data);
      return MealPlan.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> deleteMealPlan(int id) async {
    try {
      await _dio.delete(ApiConfig.mealPlanById(id));
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<MealItem> addMealItem(
      int mealPlanId, Map<String, dynamic> data) async {
    try {
      final response =
          await _dio.post(ApiConfig.mealPlanItems(mealPlanId), data: data);
      return MealItem.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> deleteMealItem(int itemId) async {
    try {
      await _dio.delete(ApiConfig.mealItemById(itemId));
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // --- Notification APIs ---
  Future<PaginatedNotifications> getNotifications(
      {int page = 0, int size = 20, bool? unreadOnly}) async {
    try {
      final response =
          await _dio.get(ApiConfig.notifications, queryParameters: {
        'page': page,
        'size': size,
        if (unreadOnly != null) 'unreadOnly': unreadOnly,
      });
      return PaginatedNotifications.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<NotificationCount> getNotificationCount() async {
    try {
      final response = await _dio.get(ApiConfig.notificationCount);
      return NotificationCount.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> markNotificationsAsRead(List<int> ids) async {
    try {
      await _dio
          .post(ApiConfig.notificationMarkRead, data: {'notificationIds': ids});
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> markAllNotificationsAsRead() async {
    try {
      await _dio.post(ApiConfig.notificationMarkAllRead);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> deleteNotification(int id) async {
    try {
      await _dio.delete(ApiConfig.notificationById(id));
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // --- Product APIs ---
  Future<List<Product>> getProducts({int page = 0, int size = 20}) async {
    try {
      final response = await _dio.get(ApiConfig.products, queryParameters: {
        'page': page,
        'size': size,
      });
      final data = response.data['data'];
      if (data == null) return [];
      // Handle paginated response
      if (data is Map && data['content'] != null) {
        return (data['content'] as List)
            .map((i) => Product.fromJson(i))
            .toList();
      }
      if (data is List) {
        return data.map((i) => Product.fromJson(i)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Product> getProductById(int id) async {
    try {
      final response = await _dio.get(ApiConfig.productById(id));
      return Product.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<List<Product>> searchProducts(String name,
      {int page = 0, int size = 20}) async {
    try {
      final response =
          await _dio.get(ApiConfig.searchProducts, queryParameters: {
        'name': name,
        'page': page,
        'size': size,
      });
      final data = response.data['data'];
      if (data == null) return [];
      // Handle paginated response
      if (data is Map && data['content'] != null) {
        return (data['content'] as List)
            .map((i) => Product.fromJson(i))
            .toList();
      }
      if (data is List) {
        return data.map((i) => Product.fromJson(i)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<List<Product>> getProductsByCategory(int categoryId,
      {int page = 0, int size = 20}) async {
    try {
      final response = await _dio
          .get(ApiConfig.productsByCategory(categoryId), queryParameters: {
        'page': page,
        'size': size,
      });
      final data = response.data['data'];
      if (data == null) return [];
      // Handle paginated response
      if (data is Map && data['content'] != null) {
        return (data['content'] as List)
            .map((i) => Product.fromJson(i))
            .toList();
      }
      if (data is List) {
        return data.map((i) => Product.fromJson(i)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// POST /api/v1/admin/master-products - Create a new product
  Future<Product> createProduct(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/admin/master-products', data: data);
      return Product.fromJson(
          response.data['data'] ?? response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// PUT /api/v1/admin/master-products/{id} - Update a product
  Future<Product> updateProduct(int id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/admin/master-products/$id', data: data);
      return Product.fromJson(
          response.data['data'] ?? response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// DELETE /api/v1/admin/master-products/{id} - Delete a product
  Future<void> deleteProduct(int id) async {
    try {
      await _dio.delete('/admin/master-products/$id');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // --- AI Services ---
  /// Generate AI-powered recipe suggestion based on available ingredients
  Future<Map<String, dynamic>> generateAIRecipeSuggestion({
    required List<String> availableIngredients,
    String? dietaryPreference,
    String? cuisineType,
    int? servings,
  }) async {
    try {
      final requestData = {
        'availableIngredients': availableIngredients,
        if (dietaryPreference != null && dietaryPreference.isNotEmpty)
          'dietaryPreference': dietaryPreference,
        if (cuisineType != null && cuisineType.isNotEmpty)
          'cuisineType': cuisineType,
        if (servings != null) 'servings': servings,
      };

      final response =
          await _dio.post('/ai/recipes/suggest', data: requestData);
      return response.data['data'];
    } on DioException catch (e) {
      if (e.response?.statusCode == 429) {
        throw Exception(
            'Bạn đã vượt quá giới hạn 10 yêu cầu AI mỗi ngày. Vui lòng thử lại sau.');
      } else if (e.response?.statusCode == 401) {
        throw Exception('Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.');
      }
      throw _handleDioError(e);
    }
  }

  /// Check remaining AI requests for current user
  Future<Map<String, dynamic>> checkAIRateLimit() async {
    try {
      final response = await _dio.get('/ai/recipes/rate-limit');
      return response.data['data'];
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // --- Admin: User Management ---

  /// GET /api/v1/admin/users - Lấy danh sách tất cả người dùng với phân trang
  Future<Map<String, dynamic>> getAdminUsers({int? page, int? size}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (page != null) queryParams['page'] = page;
      if (size != null) queryParams['size'] = size;

      final response =
          await _dio.get('/admin/users', queryParameters: queryParams);
      return response.data['data'] ?? response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// GET /api/v1/admin/users/{id} - Lấy thông tin chi tiết của một người dùng cụ thể
  Future<Map<String, dynamic>> getAdminUserById(int id) async {
    try {
      final response = await _dio.get('/admin/users/$id');
      return response.data['data'] ?? response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// POST /api/v1/admin/users - Tạo một người dùng mới
  Future<Map<String, dynamic>> createAdminUser(
      Map<String, dynamic> userData) async {
    try {
      final response = await _dio.post('/admin/users', data: userData);
      return response.data['data'] ?? response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// PATCH /api/v1/admin/users/{id}/status - Kích hoạt hoặc vô hiệu hóa tài khoản
  Future<Map<String, dynamic>> updateAdminUserStatus(
      int id, bool isActive) async {
    try {
      final response = await _dio.patch(
        '/admin/users/$id/status',
        data: {'isActive': isActive},
      );
      return response.data['data'] ?? response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// PATCH /api/v1/admin/users/{id}/roles - Thay đổi vai trò của người dùng
  Future<Map<String, dynamic>> updateAdminUserRoles(
      int id, List<String> roles) async {
    try {
      final response = await _dio.patch(
        '/admin/users/$id/roles',
        data: {'roles': roles},
      );
      return response.data['data'] ?? response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// POST /api/v1/admin/users/{id}/reset-password - Đặt lại mật khẩu cho người dùng
  Future<void> resetAdminUserPassword(int id) async {
    try {
      await _dio.post('/admin/users/$id/reset-password');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// DELETE /api/v1/admin/users/{id} - Xóa một người dùng khỏi hệ thống
  Future<void> deleteAdminUser(int id) async {
    try {
      await _dio.delete('/admin/users/$id');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // --- Admin: Category Management ---

  /// GET /api/v1/categories - Lấy tất cả danh mục
  Future<List<Category>> getCategories() async {
    try {
      final response = await _dio.get('/categories');
      final data = response.data['data'] ?? response.data;

      if (data is List) {
        return data
            .map((c) => Category.fromJson(c as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// GET /api/v1/categories/{id} - Lấy danh mục theo ID
  Future<Category> getCategoryById(int id) async {
    try {
      final response = await _dio.get('/categories/$id');
      return Category.fromJson(
          response.data['data'] ?? response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// GET /api/v1/categories/search?name= - Tìm kiếm danh mục
  Future<List<Category>> searchCategories(String name) async {
    try {
      final response =
          await _dio.get('/categories/search', queryParameters: {'name': name});
      final data = response.data['data'] ?? response.data;

      if (data is List) {
        return data
            .map((c) => Category.fromJson(c as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// POST /api/v1/categories - Tạo danh mục mới
  Future<Category> createCategory(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/categories', data: data);
      return Category.fromJson(
          response.data['data'] ?? response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// PUT /api/v1/categories/{id} - Cập nhật danh mục
  Future<Category> updateCategory(int id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/categories/$id', data: data);
      return Category.fromJson(
          response.data['data'] ?? response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// DELETE /api/v1/categories/{id} - Xóa danh mục
  Future<void> deleteCategory(int id) async {
    try {
      await _dio.delete('/categories/$id');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
}
