import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  static String get baseUrl {
    const String apiVersion = '/v1';
    String base;

    if (kIsWeb) {
      base = 'http://127.0.0.1:8080/api';
    } else {
      if (Platform.isAndroid) {
        base = 'http://10.0.2.2:8080/api';
      } else {
        base = 'http://127.0.0.1:8080/api';
      }
    }
    return base + apiVersion;
  }

  static String? getImageUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return path;
    return null; // Adjust if you have a different base URL for images
  }

  // --- Auth & User ---
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String userSearch = '/users/search';
  static const String currentUser = '/users/me';
  static const String userAvatar = '/users/me/avatar';

  // --- Friend Endpoints ---
  static const String friends = '/friends';
  static const String friendRequests = '/friends/requests';
  static const String sentFriendRequests = '/friends/requests/sent';
  static const String receivedFriendRequests = '/friends/requests/received';
  static String respondToFriendRequest(String id) => '/friends/requests/$id/respond';
  static String cancelFriendRequest(String id) => '/friends/requests/$id';
  static String unfriend(String userId) => '/friends/$userId';
  static String friendStatus(String userId) => '/friends/status/$userId';

  // --- Family Endpoints ---
  static const String families = '/families';
  static const String joinFamily = '/families/join';
  static String familyById(int id) => '/families/$id';
  static String familyMembers(int id) => '/families/$id/members';
  static String leaveFamily(int id) => '/families/$id/leave';
  static String familyInviteCode(int id) => '/families/$id/invite-code';
  static String familyAvatar(int familyId) => '/families/$familyId/avatar';
  static String inviteFriendToFamily(int familyId, int friendId) => '/families/$familyId/invite/$friendId';
  static const String familyInvitations = '/families/invitations';
  static String respondToFamilyInvitation(int id) => '/families/invitations/$id/respond';

  // --- Fridge Endpoints ---
  static const String fridgeItems = '/fridge-items';
  static String familyFridgeItems(int familyId) => '/families/$familyId/fridge-items';
  static String fridgeItemById(int id) => '/fridge-items/$id';

  // --- Recipe Endpoints ---
  static const String recipes = '/recipes';
  static String recipeById(int id) => '/recipes/$id';
  static const String searchRecipes = '/recipes/search';
  static const String myRecipes = '/recipes/my-recipes';
  static String recipeSuggestions(int familyId) => '/recipes/suggestions/$familyId';

  // --- Shopping List Endpoints ---
  static const String shoppingLists = '/shopping-lists';
  static String familyShoppingLists(int familyId) => '/families/$familyId/shopping-lists';
  static String familyActiveShoppingLists(int familyId) => '/families/$familyId/shopping-lists/active';
  static String shoppingListById(int id) => '/shopping-lists/$id';
  static String shoppingListItems(int listId) => '/shopping-lists/$listId/items';
  static String shoppingListItemsBulk(int listId) => '/shopping-lists/$listId/items/bulk';
  static String shoppingItemById(int id) => '/shopping-items/$id';

  // --- Meal Plan Endpoints ---
  static const String mealPlans = '/meal-plans';
  static String familyMealPlans(int familyId) => '/families/$familyId/meal-plans';
  static String familyDailyMealPlans(int familyId) => '/families/$familyId/meal-plans/daily';
  static String familyWeeklyMealPlans(int familyId) => '/families/$familyId/meal-plans/weekly';
  static String mealPlanById(int id) => '/meal-plans/$id';
  static String mealPlanItems(int mealPlanId) => '/meal-plans/$mealPlanId/items';
  static String mealItemById(int id) => '/meal-items/$id';

  // --- Notification Endpoints ---
  static const String notifications = '/notifications';
  static const String notificationCount = '/notifications/count';
  static const String markAsRead = '/notifications/read';
  static const String markAsUnread = '/notifications/unread';
  static const String markAllAsRead = '/notifications/read-all';
  static String deleteNotification(String id) => '/notifications/$id';
  static const String deleteAllNotifications = '/notifications';
}
