import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';
import '../config/tenant_config.dart';

class ApiClient {
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

  void applyTenant(TenantConfig? tenant) {
    dio.options.baseUrl = AppConfig.normalizeApiBaseUrl(tenant?.apiBaseUrl);
  }
}

class _AuthInterceptor extends QueuedInterceptorsWrapper {
  final FlutterSecureStorage _storage;
  final Dio _dio;

  _AuthInterceptor(this._storage, this._dio);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.read(key: AppConfig.tokenKey);
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
      // Jangan refresh token saat login/register gagal.
      if (path.contains('/auth/login') ||
          path.contains('/auth/register') ||
          path.contains('/auth/refresh')) {
        return handler.next(err);
      }

      try {
        final refreshToken = await _storage.read(
          key: AppConfig.refreshTokenKey,
        );
        if (refreshToken == null) return handler.next(err);

        // Backend expects refresh_token in request body
        final response = await _dio.post(
          '/auth/refresh',
          data: {'refresh_token': refreshToken},
        );

        final newToken = response.data['data']['access_token'] as String;
        final newRefresh = response.data['data']['refresh_token'] as String?;
        await _storage.write(key: AppConfig.tokenKey, value: newToken);
        if (newRefresh != null) {
          await _storage.write(
            key: AppConfig.refreshTokenKey,
            value: newRefresh,
          );
        }

        final opts = err.requestOptions;
        opts.headers['Authorization'] = 'Bearer $newToken';
        final retryResponse = await _dio.fetch(opts);
        return handler.resolve(retryResponse);
      } catch (_) {
        await Future.wait([
          _storage.delete(key: AppConfig.tokenKey),
          _storage.delete(key: AppConfig.refreshTokenKey),
        ]);
        return handler.next(err);
      }
    }
    return handler.next(err);
  }
}
