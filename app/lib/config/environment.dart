import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Environment configuration for different deployment stages
enum Environment { development, staging, production }

class AppConfig {
  /// Current environment - change this for different builds
  static Environment currentEnvironment = Environment.production;

  /// API Base URL based on environment
  static String get apiBaseUrl {
    switch (currentEnvironment) {
      case Environment.development:
        // Local development
        if (kIsWeb) {
          return 'http://127.0.0.1:8080/api/v1';
        } else if (!kIsWeb && Platform.isAndroid) {
          return 'http://10.0.2.2:8080/api/v1'; // Android emulator
        } else {
          return 'http://127.0.0.1:8080/api/v1'; // iOS simulator
        }

      case Environment.staging:
        // Staging server for testing
        return 'https://smart-grocery-staging.ondigitalocean.app/api/v1';

      case Environment.production:
        // Production server
        // TODO: Replace with your actual DigitalOcean App Platform URL
        return 'https://smart-grocery-api-xxxxx.ondigitalocean.app/api/v1';
    }
  }

  /// File Base URL for serving images and static files
  static String get fileBaseUrl {
    switch (currentEnvironment) {
      case Environment.development:
        if (kIsWeb) {
          return 'http://127.0.0.1:8080';
        } else if (!kIsWeb && Platform.isAndroid) {
          return 'http://10.0.2.2:8080';
        } else {
          return 'http://127.0.0.1:8080';
        }

      case Environment.staging:
        return 'https://smart-grocery-staging.ondigitalocean.app';

      case Environment.production:
        // TODO: Replace with your actual DigitalOcean App Platform URL
        return 'https://smart-grocery-api-xxxxx.ondigitalocean.app';
    }
  }

  /// App version for display
  static String get appVersion => '1.0.0';

  /// Build number
  static String get buildNumber => '1';

  /// Is production build
  static bool get isProduction => currentEnvironment == Environment.production;

  /// Is development build
  static bool get isDevelopment => currentEnvironment == Environment.development;

  /// Enable debug features
  static bool get enableDebugFeatures => !isProduction;

  /// API timeout duration
  static Duration get apiTimeout {
    return isProduction 
        ? const Duration(seconds: 30) 
        : const Duration(seconds: 60);
  }
}
