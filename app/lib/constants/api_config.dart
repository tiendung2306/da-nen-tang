import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  static String get baseUrl {
    return 'https://da-nen-tang-be.onrender.com/api/v1';
  }

  /// Base URL without API version for file serving
  static String get fileBaseUrl {
    return 'https://da-nen-tang-be.onrender.com';
  }

  /// Build full URL for an image path returned from API
  /// The API returns paths like "/files/families/uuid.jpg"
  static String? getImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return null;
    // If already a full URL, return as-is
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }
    return '$fileBaseUrl$imagePath';
  }

  // --- Auth & User ---
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String me = '/auth/me';
  static const String userAvatar = '/auth/me/avatar';
  static const String userSearch = '/users/search';

  // --- Notification Endpoints ---
  static const String notifications = '/notifications';
  static const String notificationCount = '/notifications/count';
  static const String notificationMarkRead = '/notifications/mark-read';
  static const String notificationMarkAllRead = '/notifications/mark-all-read';
  static String notificationById(int id) => '/notifications/$id';

  // --- Friend Endpoints ---
  static const String friends = '/friends';
  static const String friendRequests = '/friends/requests';
  static const String sentFriendRequests = '/friends/requests/sent';
  static const String receivedFriendRequests = '/friends/requests/received';
  static String respondToFriendRequest(String id) =>
      '/friends/requests/$id/respond';
  static String cancelFriendRequest(String id) => '/friends/requests/$id';
  static String unfriend(String userId) => '/friends/$userId';
  static String friendStatus(String userId) => '/friends/status/$userId';

  // --- Family Endpoints ---
  static const String families = '/families';
  static const String joinFamily = '/families/join';
  static const String familyInvitations = '/families/invitations';
  static String respondToFamilyInvitation(int id) =>
      '/families/invitations/$id/respond';
  static String familyById(int id) => '/families/$id';
  static String familyImage(int id) => '/families/$id/image';
  static String familyMembers(int id) => '/families/$id/members';
  static String leaveFamily(int id) => '/families/$id/leave';
  static String familyInviteCode(int id) => '/families/$id/invite-code';
  static String regenerateInviteCode(int id) =>
      '/families/$id/regenerate-invite-code';
  static String familyMember(int familyId, int userId) =>
      '/families/$familyId/members/$userId';
  static String inviteFriendToFamily(int familyId, int friendId) =>
      '/families/$familyId/invite/$friendId';

  // --- Fridge Endpoints ---
  static const String fridgeItems = '/fridge-items';
  static String familyFridgeItems(int familyId) =>
      '/families/$familyId/fridge-items';
  static String activeFridgeItems(int familyId) =>
      '/families/$familyId/fridge-items/active';
  static String expiringFridgeItems(int familyId) =>
      '/families/$familyId/fridge-items/expiring';
  static String expiredFridgeItems(int familyId) =>
      '/families/$familyId/fridge-items/expired';
  static String fridgeStatistics(int familyId) =>
      '/families/$familyId/fridge-items/statistics';
  static String fridgeItemById(int id) => '/fridge-items/$id';
  static String consumeFridgeItem(int id) => '/fridge-items/$id/consume';
  static String discardFridgeItem(int id) => '/fridge-items/$id/discard';

  // --- Recipe Endpoints ---
  static const String recipes = '/recipes';
  static String recipeById(int id) => '/recipes/$id';
  static const String searchRecipes = '/recipes/search'; // query param: title
  static const String myRecipes = '/recipes/my-recipes';
  static String recipeSuggestions(int familyId) =>
      '/recipes/suggestions/$familyId';

  // --- Shopping List Endpoints ---
  static const String shoppingLists = '/shopping-lists';
  static String shoppingListById(int id) => '/shopping-lists/$id';
  static String familyShoppingLists(int familyId) =>
      '/families/$familyId/shopping-lists';
  static String familyActiveShoppingLists(int familyId) =>
      '/families/$familyId/shopping-lists/active';
  static String shoppingListItems(int listId) =>
      '/shopping-lists/$listId/items';
  static String shoppingListItemsBulk(int listId) =>
      '/shopping-lists/$listId/items/bulk';
  static String shoppingItemById(int itemId) => '/shopping-items/$itemId';

  // --- Meal Plan Endpoints ---
  static const String mealPlans = '/meal-plans';
  static String mealPlanById(int id) => '/meal-plans/$id';
  static String familyMealPlans(int familyId) =>
      '/families/$familyId/meal-plans';
  static String familyDailyMealPlans(int familyId) =>
      '/families/$familyId/meal-plans/daily';
  static String familyWeeklyMealPlans(int familyId) =>
      '/families/$familyId/meal-plans/weekly';
  static String mealPlanItems(int mealPlanId) =>
      '/meal-plans/$mealPlanId/items';
  static String mealItemById(int itemId) => '/meal-items/$itemId';

  // --- Product Endpoints ---
  static const String products = '/master-products';
  static String productById(int id) => '/master-products/$id';
  static const String searchProducts =
      '/master-products/search'; // query param: name
  static String productsByCategory(int categoryId) =>
      '/master-products/by-category/$categoryId';
}
