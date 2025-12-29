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

  // --- Auth Endpoints ---
  static const String login = '/auth/login';
  static const String register = '/auth/register';

  // --- Fridge Item Endpoints ---
  static const String fridgeItems = '/fridge-items';
  static String familyFridgeItems(int familyId) => '/families/$familyId/fridge-items';
  // ... other fridge endpoints
  static String fridgeItemById(int id) => '/fridge-items/$id';

  // --- Family Endpoints ---
  static const String families = '/families';
  static const String joinFamily = '/families/join';
  static String familyById(int id) => '/families/$id';
  static String familyMembers(int id) => '/families/$id/members';
  static String leaveFamily(int id) => '/families/$id/leave';
  static String regenerateInviteCode(int id) => '/families/$id/regenerate-invite-code';
  static String familyMember(int familyId, int userId) => '/families/$familyId/members/$userId';
}
