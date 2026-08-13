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
      'https://api.akademihub.id/api/$apiVersion';
  static const String approvedApiDomain = 'akademihub.id';

  static String get apiBaseUrl {
    if (!kDebugMode) return _apiBaseUrlProd;

    return !kIsWeb && defaultTargetPlatform == TargetPlatform.android
        ? _apiBaseUrlAndroidEmulator
        : _apiBaseUrlLocalhost;
  }

  static String normalizeApiBaseUrl(
    String? value, {
    bool allowDevelopmentHosts = kDebugMode,
  }) {
    final uri = Uri.tryParse(value?.trim() ?? '');
    if (uri == null ||
        !uri.hasScheme ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      return apiBaseUrl;
    }

    final host = uri.host.toLowerCase();
    final isApprovedHost =
        host == approvedApiDomain || host.endsWith('.$approvedApiDomain');
    final isDevelopmentHost =
        allowDevelopmentHosts &&
        const {'localhost', '127.0.0.1', '10.0.2.2'}.contains(host);
    final validScheme = isApprovedHost
        ? uri.scheme == 'https' && (!uri.hasPort || uri.port == 443)
        : isDevelopmentHost && uri.scheme == 'http';
    if (!validScheme || (!isApprovedHost && !isDevelopmentHost)) {
      return apiBaseUrl;
    }

    final normalized = uri.normalizePath();
    final path = normalized.path.replaceFirst(RegExp(r'/+$'), '');
    return normalized.replace(path: path).toString();
  }

  // ── Token storage keys ─────────────────────────────────────────────────────
  static const String tokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';

  // ── HTTP timeouts ──────────────────────────────────────────────────────────
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 60);

  // ── Pagination ─────────────────────────────────────────────────────────────
  static const int defaultPageSize = 15;
}
