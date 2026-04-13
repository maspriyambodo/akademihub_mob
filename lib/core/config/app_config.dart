import 'package:flutter/foundation.dart';

class AppConfig {
  static const String appName = 'AkademiHub';
  static const String apiVersion = 'v1';

  // Change to your actual backend URL
  static const String _baseUrlProd = 'https://app.akademihub.id/api';
  static const String _baseUrlDev =
      'http://10.0.2.2/api'; // Android emulator localhost

  static String get baseUrl => kDebugMode ? _baseUrlDev : _baseUrlProd;
  static String get apiBaseUrl => '$baseUrl/$apiVersion';

  // WebSocket (Laravel Reverb)
  static const String _wsUrlDev = 'ws://10.0.2.2:8080';
  static const String _wsUrlProd = 'wss://ws.akademihub.id';
  static String get wsUrl => kDebugMode ? _wsUrlDev : _wsUrlProd;
  static const String wsAppKey = 'akademihub-key';

  // Token storage keys
  static const String tokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_data';

  // HTTP timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 60);

  // Pagination
  static const int defaultPageSize = 15;
}
