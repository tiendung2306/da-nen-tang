import 'package:dio/dio.dart';
import 'package:flutter_boilerplate/services/shared_pref/shared_pref.dart';

const BASE_URL = 'https://dev-api.timtour.vn/api/v1';

/// Legacy ApiService - kept for reference. 
/// Use lib/services/api/api_service.dart instead.
class LegacyApiService {
  late final Dio client;

  LegacyApiService() {
    client = Dio();
    client.options.baseUrl = BASE_URL;
    client.options.connectTimeout = const Duration(milliseconds: 5000);
    client.options.receiveTimeout = const Duration(milliseconds: 30000);
    client.options.followRedirects = false;
    client.options.validateStatus = (status) {
      return status != null && status < 500;
    };
  }

  void setToken(String authToken) {
    client.options.headers['Authorization'] = 'Bearer $authToken';
  }

  Future<void> clientSetup() async {
    final String? authToken = await SharedPref.getToken();
    if (authToken != null && authToken.isNotEmpty) {
      client.options.headers['Authorization'] = 'Bearer $authToken';
    }
  }
}
