import 'package:dio/dio.dart';
import 'package:flutter_boilerplate/services/api/api_service.dart';
import 'package:flutter_boilerplate/services/locator.dart';

/// Legacy controller - kept for reference.
/// Should migrate to use ApiService methods directly.
class UserController {
  UserController();

  static ApiService apiService = locator<ApiService>();
}
