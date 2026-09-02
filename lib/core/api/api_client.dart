import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';

class ApiClient {
  static Duration serverTimeOffset = Duration.zero;
  static DateTime get currentServerTime =>
      DateTime.now().toUtc().add(serverTimeOffset);

  late final Dio dio;
  final FlutterSecureStorage _storage;

  ApiClient(this._storage) {
    dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
        headers: {'Accept': 'application/json'},
      ),
    );

    dio.interceptors.addAll([
      _ServerDateInterceptor(),
      _AuthInterceptor(_storage, dio),
      if (kDebugMode)
        LogInterceptor(
          requestBody: false,
          responseBody: false,
          requestHeader: false,
          responseHeader: false,
          logPrint: (obj) => debugPrint(obj.toString()),
        ),
    ]);
  }
}

class _ServerDateInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    try {
      final dateHeader = response.headers.value('date');
      if (dateHeader != null) {
        final serverTime = HttpDate.parse(dateHeader).toUtc();
        ApiClient.serverTimeOffset = serverTime.difference(
          DateTime.now().toUtc(),
        );
      }
    } catch (_) {}
    super.onResponse(response, handler);
  }
}

class _AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _storage;
  final Dio _dio;
  Future<String?>? _refreshTokenFuture;

  _AuthInterceptor(this._storage, this._dio);

  static const _safeRetryMethods = {'GET', 'HEAD', 'OPTIONS'};

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.read(key: AppConfig.tokenKey);
    final tokenOrigin = await _storage.read(key: AppConfig.tokenOriginKey);
    final currentOrigin = AppConfig.extractOrigin(options.baseUrl);

    if (tokenOrigin != null &&
        currentOrigin != null &&
        tokenOrigin != currentOrigin) {
      // Origin mismatch — clear tokens & do not attach cross-origin token!
      await _clearTokens();
      return handler.next(options);
    }

    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      final path = err.requestOptions.path;
      final isRetry = err.requestOptions.extra['is_retry'] == true;
      final allowPostRetry =
          err.requestOptions.extra['idempotent_retry'] == true ||
          path.contains('/akademik/absensi-siswa/check-in') ||
          path.contains('/akademik/absensi-siswa/check-out');

      // Jangan refresh token saat login, register, refresh, logout gagal, atau jika request sudah retry.
      if (path.contains('/auth/login') ||
          path.contains('/auth/register') ||
          path.contains('/auth/refresh') ||
          path.contains('/auth/logout') ||
          isRetry) {
        if (isRetry) {
          await _clearTokens();
        }
        return handler.next(err);
      }

      try {
        final newToken = await _getRefreshedToken();
        if (newToken == null) {
          return handler.next(err);
        }

        final opts = err.requestOptions;
        final isSafeMethod = _safeRetryMethods.contains(
          opts.method.toUpperCase(),
        );
        if (!isSafeMethod && !allowPostRetry) {
          return handler.next(err);
        }
        opts.headers['Authorization'] = 'Bearer $newToken';
        opts.extra['is_retry'] = true;

        final retryResponse = await _dio.fetch(opts);
        return handler.resolve(retryResponse);
      } catch (_) {
        return handler.next(err);
      }
    }
    return handler.next(err);
  }

  Future<String?> _getRefreshedToken() async {
    if (_refreshTokenFuture != null) {
      return _refreshTokenFuture;
    }

    _refreshTokenFuture = _performRefresh();
    try {
      return await _refreshTokenFuture;
    } finally {
      _refreshTokenFuture = null;
    }
  }

  Future<String?> _performRefresh() async {
    try {
      final tokenOrigin = await _storage.read(key: AppConfig.tokenOriginKey);
      final currentOrigin = AppConfig.extractOrigin(_dio.options.baseUrl);

      if (tokenOrigin != null &&
          currentOrigin != null &&
          tokenOrigin != currentOrigin) {
        // Stop cross-origin refresh token request & clear session
        await _clearTokens();
        return null;
      }

      final refreshToken = await _storage.read(key: AppConfig.refreshTokenKey);
      if (refreshToken == null || refreshToken.isEmpty) {
        await _clearTokens();
        return null;
      }

      // Backend expects refresh_token in request body
      final response = await _dio.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
        options: Options(extra: {'is_retry': true}),
      );

      final body = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};
      final data = body['data'] is Map<String, dynamic>
          ? body['data'] as Map<String, dynamic>
          : body;

      final newToken = data['access_token'] as String?;
      final newRefresh = data['refresh_token'] as String?;

      if (newToken == null || newToken.isEmpty) {
        await _clearTokens();
        return null;
      }

      await _storage.write(key: AppConfig.tokenKey, value: newToken);
      if (newRefresh != null && newRefresh.isNotEmpty) {
        await _storage.write(key: AppConfig.refreshTokenKey, value: newRefresh);
      }

      return newToken;
    } catch (_) {
      await _clearTokens();
      return null;
    }
  }

  Future<void> _clearTokens() async {
    await Future.wait([
      _storage.delete(key: AppConfig.tokenKey),
      _storage.delete(key: AppConfig.refreshTokenKey),
      _storage.delete(key: AppConfig.tokenOriginKey),
    ]);
  }
}
