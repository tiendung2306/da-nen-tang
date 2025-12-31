import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_boilerplate/constants/api_config.dart';
import 'package:flutter_boilerplate/models/auth_model.dart';
import 'package:flutter_boilerplate/models/family_invitation_model.dart';
import 'package:flutter_boilerplate/models/family_model.dart';
import 'package:flutter_boilerplate/models/friend_model.dart';
import 'package:flutter_boilerplate/models/fridge_item.dart';
import 'package:flutter_boilerplate/models/meal_plan_model.dart';
import 'package:flutter_boilerplate/models/notification_model.dart';
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

  Future<UserInfo> register(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(ApiConfig.register, data: data);
      return UserInfo.fromJson(response.data['data']);
    } on DioException catch (e) { throw _handleDioError(e); }
  }

  Future<UserInfo> getCurrentUser() async {
    try {
      final response = await _dio.get(ApiConfig.currentUser);
      return UserInfo.fromJson(response.data['data']);
    } on DioException catch (e) { throw _handleDioError(e); }
  }

  Future<UserInfo> uploadUserAvatar(XFile image) async {
    try {
      final formData = FormData.fromMap({
        'avatar': await MultipartFile.fromFile(image.path, filename: image.name),
      });
      final response = await _dio.post(ApiConfig.userAvatar, data: formData);
      return UserInfo.fromJson(response.data['data']);
    } on DioException catch (e) { throw _handleDioError(e); }
  }

  Future<UserInfo> deleteUserAvatar() async {
    try {
      final response = await _dio.delete(ApiConfig.userAvatar);
      return UserInfo.fromJson(response.data['data']);
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
      await _dio.post(ApiConfig.respondToFriendRequest(requestId), data: {'accept': accept});
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

  Future<List<FamilyMember>> getFamilyMembers(int familyId) async {
    try {
      final response = await _dio.get(ApiConfig.familyMembers(familyId));
      return (response.data['data'] as List).map((i) => FamilyMember.fromJson(i)).toList();
    } on DioException catch (e) { throw _handleDioError(e); }
  }

  Future<Family> createFamily(Map<String, dynamic> data) async {
    try {
      final formData = FormData.fromMap({
        'name': data['name'],
        if (data['description'] != null) 'description': data['description'],
        if (data['friendIds'] != null && (data['friendIds'] as List).isNotEmpty)
          'friendIds': (data['friendIds'] as List).map((id) => id.toString()).toList(),
      });
      final response = await _dio.post(ApiConfig.families, data: formData);
      return Family.fromJson(response.data['data']);
    } on DioException catch (e) { throw _handleDioError(e); }
  }

  Future<Family> joinFamily(String inviteCode) async {
    try {
      final response = await _dio.post(ApiConfig.joinFamily, data: {'inviteCode': inviteCode});
      return Family.fromJson(response.data['data']);
    } on DioException catch (e) { throw _handleDioError(e); }
  }

  Future<void> leaveFamily(int familyId) async {
    try {
      await _dio.post(ApiConfig.leaveFamily(familyId));
    } on DioException catch (e) { throw _handleDioError(e); }
  }

  Future<List<FamilyInvitation>> getFamilyInvitations() async {
    try {
      final response = await _dio.get(ApiConfig.familyInvitations);
      return (response.data['data'] as List).map((i) => FamilyInvitation.fromJson(i)).toList();
    } on DioException catch (e) { throw _handleDioError(e); }
  }

  Future<void> respondToFamilyInvitation(int invitationId, bool accept) async {
    try {
      await _dio.post(ApiConfig.respondToFamilyInvitation(invitationId), data: {'accept': accept});
    } on DioException catch (e) { throw _handleDioError(e); }
  }

  Future<String> generateInviteCode(int familyId) async {
    try {
      final response = await _dio.post(ApiConfig.familyInviteCode(familyId));
      return response.data['data']['inviteCode'] as String;
    } on DioException catch (e) { throw _handleDioError(e); }
  }

  Future<Family> updateFamilyWithImage(int familyId, Map<String, dynamic> familyData, {XFile? image}) async {
    try {
      final formData = FormData.fromMap({
        'name': familyData['name'],
        if (familyData['description'] != null) 'description': familyData['description'],
        if (image != null) 'avatar': await MultipartFile.fromFile(image.path, filename: image.name),
      });
      final response = await _dio.put(ApiConfig.familyById(familyId), data: formData);
      return Family.fromJson(response.data['data']);
    } on DioException catch (e) { throw _handleDioError(e); }
  }

  Future<Family> deleteFamilyImage(int familyId) async {
    try {
      final response = await _dio.delete(ApiConfig.familyAvatar(familyId));
      return Family.fromJson(response.data['data']);
    } on DioException catch (e) { throw _handleDioError(e); }
  }

  Future<void> inviteFriendToFamily(int familyId, int friendId) async {
    try {
      await _dio.post(ApiConfig.inviteFriendToFamily(familyId, friendId));
    } on DioException catch (e) { throw _handleDioError(e); }
  }

  // --- Fridge APIs ---
  Future<List<FridgeItem>> getFridgeItems(int familyId, {int page = 0, int size = 20}) async {
    try {
      final response = await _dio.get(ApiConfig.familyFridgeItems(familyId), queryParameters: {'page': page, 'size': size});
      final paginatedData = response.data['data'];
      if (paginatedData != null && paginatedData['content'] is List) {
        return (paginatedData['content'] as List).map((i) => FridgeItem.fromJson(i)).toList();
      }
      return [];
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

  Future<Recipe> createRecipe(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(ApiConfig.recipes, data: data);
      return Recipe.fromJson(response.data['data']);
    } on DioException catch (e) { throw _handleDioError(e); }
  }

  // --- Shopping List APIs ---
  Future<List<ShoppingList>> getShoppingLists(int familyId) async {
    try {
      final response = await _dio.get(ApiConfig.familyShoppingLists(familyId));
      return (response.data['data'] as List).map((i) => ShoppingList.fromJson(i)).toList();
    } on DioException catch (e) { throw _handleDioError(e); }
  }

  Future<List<ShoppingList>> getActiveShoppingLists(int familyId) async {
    try {
      final response = await _dio.get(ApiConfig.familyActiveShoppingLists(familyId));
      return (response.data['data'] as List).map((i) => ShoppingList.fromJson(i)).toList();
    } on DioException catch (e) { throw _handleDioError(e); }
  }

  Future<ShoppingList> getShoppingListById(int id) async {
    try {
      final response = await _dio.get(ApiConfig.shoppingListById(id));
      return ShoppingList.fromJson(response.data['data']);
    } on DioException catch (e) { throw _handleDioError(e); }
  }

  Future<ShoppingList> createShoppingList(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(ApiConfig.shoppingLists, data: data);
      return ShoppingList.fromJson(response.data['data']);
    } on DioException catch (e) { throw _handleDioError(e); }
  }

  Future<ShoppingList> updateShoppingList(int id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.patch(ApiConfig.shoppingListById(id), data: data);
      return ShoppingList.fromJson(response.data['data']);
    } on DioException catch (e) { throw _handleDioError(e); }
  }

  Future<void> deleteShoppingList(int id) async {
    try {
      await _dio.delete(ApiConfig.shoppingListById(id));
    } on DioException catch (e) { throw _handleDioError(e); }
  }

  Future<ShoppingItem> addShoppingItem(int listId, Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(ApiConfig.shoppingListItems(listId), data: data);
      return ShoppingItem.fromJson(response.data['data']);
    } on DioException catch (e) { throw _handleDioError(e); }
  }

  Future<List<ShoppingItem>> addShoppingItemsBulk(int listId, List<Map<String, dynamic>> items) async {
    try {
      final response = await _dio.post(ApiConfig.shoppingListItemsBulk(listId), data: {'items': items});
      return (response.data['data'] as List).map((i) => ShoppingItem.fromJson(i)).toList();
    } on DioException catch (e) { throw _handleDioError(e); }
  }

  Future<ShoppingItem> updateShoppingItem(int itemId, Map<String, dynamic> data) async {
    try {
      final response = await _dio.patch(ApiConfig.shoppingItemById(itemId), data: data);
      return ShoppingItem.fromJson(response.data['data']);
    } on DioException catch (e) { throw _handleDioError(e); }
  }

  Future<void> deleteShoppingItem(int itemId) async {
    try {
      await _dio.delete(ApiConfig.shoppingItemById(itemId));
    } on DioException catch (e) { throw _handleDioError(e); }
  }

  // --- Meal Plan APIs ---
  Future<List<MealPlan>> getMealPlans(int familyId, {String? startDate, String? endDate}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;
      final response = await _dio.get(ApiConfig.familyMealPlans(familyId), queryParameters: queryParams);
      return (response.data['data'] as List).map((i) => MealPlan.fromJson(i)).toList();
    } on DioException catch (e) { throw _handleDioError(e); }
  }

  Future<List<MealPlan>> getDailyMealPlans(int familyId, String date) async {
    try {
      final response = await _dio.get(ApiConfig.familyDailyMealPlans(familyId), queryParameters: {'date': date});
      return (response.data['data'] as List).map((i) => MealPlan.fromJson(i)).toList();
    } on DioException catch (e) { throw _handleDioError(e); }
  }

  Future<List<MealPlan>> getWeeklyMealPlans(int familyId, String startDate) async {
    try {
      final response = await _dio.get(ApiConfig.familyWeeklyMealPlans(familyId), queryParameters: {'startDate': startDate});
      return (response.data['data'] as List).map((i) => MealPlan.fromJson(i)).toList();
    } on DioException catch (e) { throw _handleDioError(e); }
  }

  Future<MealPlan> getMealPlanById(int id) async {
    try {
      final response = await _dio.get(ApiConfig.mealPlanById(id));
      return MealPlan.fromJson(response.data['data']);
    } on DioException catch (e) { throw _handleDioError(e); }
  }

  Future<MealPlan> createMealPlan(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(ApiConfig.mealPlans, data: data);
      return MealPlan.fromJson(response.data['data']);
    } on DioException catch (e) { throw _handleDioError(e); }
  }

  Future<MealPlan> updateMealPlan(int id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put(ApiConfig.mealPlanById(id), data: data);
      return MealPlan.fromJson(response.data['data']);
    } on DioException catch (e) { throw _handleDioError(e); }
  }

  Future<void> deleteMealPlan(int id) async {
    try {
      await _dio.delete(ApiConfig.mealPlanById(id));
    } on DioException catch (e) { throw _handleDioError(e); }
  }

  Future<MealItem> addMealItem(int mealPlanId, Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(ApiConfig.mealPlanItems(mealPlanId), data: data);
      return MealItem.fromJson(response.data['data']);
    } on DioException catch (e) { throw _handleDioError(e); }
  }

  Future<void> deleteMealItem(int itemId) async {
    try {
      await _dio.delete(ApiConfig.mealItemById(itemId));
    } on DioException catch (e) { throw _handleDioError(e); }
  }

  // --- Notification APIs ---
  Future<PaginatedResponse<AppNotification>> getNotifications({int page = 0, int size = 20, bool? unreadOnly}) async {
    try {
      final response = await _dio.get(ApiConfig.notifications, queryParameters: {'page': page, 'size': size, if (unreadOnly != null) 'unreadOnly': unreadOnly});
      return PaginatedResponse<AppNotification>.fromJson(response.data['data'], (json) => AppNotification.fromJson(json as Map<String, dynamic>));
    } on DioException catch (e) { throw _handleDioError(e); }
  }

  Future<NotificationCount> getNotificationCount() async {
    try {
      final response = await _dio.get(ApiConfig.notificationCount);
      return NotificationCount.fromJson(response.data['data']);
    } on DioException catch (e) { throw _handleDioError(e); }
  }

  Future<void> markNotificationsAsRead(List<String> ids) async {
    try {
      await _dio.post(ApiConfig.markAsRead, data: {'notificationIds': ids});
    } on DioException catch (e) { throw _handleDioError(e); }
  }

  Future<void> markNotificationsAsUnread(List<String> ids) async {
    try {
      await _dio.post(ApiConfig.markAsUnread, data: {'notificationIds': ids});
    } on DioException catch (e) { throw _handleDioError(e); }
  }

  Future<void> markAllNotificationsAsRead() async {
    try {
      await _dio.post(ApiConfig.markAllAsRead);
    } on DioException catch (e) { throw _handleDioError(e); }
  }

  Future<void> deleteNotification(String id) async {
    try {
      await _dio.delete(ApiConfig.deleteNotification(id));
    } on DioException catch (e) { throw _handleDioError(e); }
  }

  Future<void> deleteAllNotifications() async {
    try {
      await _dio.delete(ApiConfig.deleteAllNotifications);
    } on DioException catch (e) { throw _handleDioError(e); }
  }
}
