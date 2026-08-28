import 'package:flutter/foundation.dart';

class AppConfig {
  AppConfig._();

  static const String appName = 'AkademiHub';
  static const String apiVersion = 'v1';

  // ── API Base URL ───────────────────────────────────────────────────────────
  // Android emulator: 10.0.2.2 = host machine localhost
  static const String _apiBaseUrlLocalhost =
      'http://127.0.0.1:8002/api/$apiVersion';
  static const String _apiBaseUrlAndroidEmulator =
      'http://10.0.2.2:8002/api/$apiVersion';
  static const String _apiBaseUrlProd =
      'https://app-api.akademihub.id/api/$apiVersion';
  static String get apiBaseUrl {
    if (!kDebugMode) return _apiBaseUrlProd;

    return !kIsWeb && defaultTargetPlatform == TargetPlatform.android
        ? _apiBaseUrlAndroidEmulator
        : _apiBaseUrlLocalhost;
  }

  // ── Token storage keys ─────────────────────────────────────────────────────
  static const String tokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String tokenOriginKey = 'token_origin';

  static String? extractOrigin(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    final uri = Uri.tryParse(url.trim());
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) return null;
    final scheme = uri.scheme.toLowerCase();
    final host = uri.host.toLowerCase();
    return '$scheme://$host${uri.hasPort ? ':${uri.port}' : ''}';
  }

  // ── HTTP timeouts ──────────────────────────────────────────────────────────
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 60);

  // ── Pagination ─────────────────────────────────────────────────────────────
  static const int defaultPageSize = 15;
}
