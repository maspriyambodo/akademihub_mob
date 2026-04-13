import 'package:flutter/foundation.dart';

class AppConfig {
  AppConfig._();

  static const String appName = 'AkademiHub';
  static const String apiVersion = 'v1';

  // ── API Base URL ───────────────────────────────────────────────────────────
  // Android emulator: 10.0.2.2 = host machine localhost
  static const String _apiBaseUrlDev = 'http://10.0.2.2:8002/api/$apiVersion';
  static const String _apiBaseUrlProd =
      'https://api.akademihub.id/api/$apiVersion';

  static String get apiBaseUrl => kDebugMode ? _apiBaseUrlDev : _apiBaseUrlProd;

  // ── Token storage keys ─────────────────────────────────────────────────────
  static const String tokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';

  // ── HTTP timeouts ──────────────────────────────────────────────────────────
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 60);

  // ── Pagination ─────────────────────────────────────────────────────────────
  static const int defaultPageSize = 15;
}
