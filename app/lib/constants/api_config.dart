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

  // --- Auth & User ---
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String userSearch = '/users/search';

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
  static String regenerateInviteCode(int id) => '/families/$id/regenerate-invite-code';
  static String familyMember(int familyId, int userId) => '/families/$familyId/members/$userId';

  // --- Fridge Endpoints ---
  static const String fridgeItems = '/fridge-items';
  static String familyFridgeItems(int familyId) => '/families/$familyId/fridge-items';
  static String activeFridgeItems(int familyId) => '/families/$familyId/fridge-items/active';
  static String expiringFridgeItems(int familyId) => '/families/$familyId/fridge-items/expiring';
  static String expiredFridgeItems(int familyId) => '/families/$familyId/fridge-items/expired';
  static String fridgeStatistics(int familyId) => '/families/$familyId/fridge-items/statistics';
  static String fridgeItemById(int id) => '/fridge-items/$id';
  static String consumeFridgeItem(int id) => '/fridge-items/$id/consume';
  static String discardFridgeItem(int id) => '/fridge-items/$id/discard';

  // --- Recipe Endpoints ---
  static const String recipes = '/recipes';
  static String recipeById(int id) => '/recipes/$id';
  static const String searchRecipes = '/recipes/search'; // query param: title
  static const String myRecipes = '/recipes/my-recipes';
  static String recipeSuggestions(int familyId) => '/recipes/suggestions/$familyId';
}
