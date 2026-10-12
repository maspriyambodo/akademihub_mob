import 'dart:io';
import 'package:dio/dio.dart';

class HttpCacheEntry {
  final dynamic data;
  final Headers headers;
  final int statusCode;
  final DateTime cachedAt;
  final Duration ttl;

  HttpCacheEntry({
    required this.data,
    required this.headers,
    required this.statusCode,
    required this.cachedAt,
    required this.ttl,
  });

  bool get isExpired => DateTime.now().isAfter(cachedAt.add(ttl));
}

/// HTTP cache interceptor for Dio to avoid redundant network calls and
/// provide offline fallback for school environments with poor connectivity.
///
/// ponytail: in-memory cache, upgrade to Hive/SQLite if cross-process persistence needed.
class HttpCacheInterceptor extends Interceptor {
  static const Duration defaultTtl = Duration(seconds: 45);
  static const int maxCacheEntries = 100;

  final Map<String, HttpCacheEntry> _cache = {};

  int get entryCount => _cache.length;

  void clear() => _cache.clear();

  void remove(String path) {
    _cache.removeWhere((k, _) => k.contains(path));
  }

  String _generateKey(RequestOptions options) {
    final authHeader = options.headers['Authorization']?.toString() ?? '';
    final authKey = authHeader.hashCode.toString();
    return '${options.method.toUpperCase()}:${options.uri}:$authKey';
  }

  bool _isCacheable(RequestOptions options) {
    if (options.method.toUpperCase() != 'GET') return false;
    if (options.extra['no_cache'] == true) return false;
    final cacheControl =
        options.headers['cache-control']?.toString().toLowerCase();
    if (cacheControl != null &&
        (cacheControl.contains('no-cache') ||
            cacheControl.contains('no-store'))) {
      return false;
    }
    return true;
  }

  Duration _getTtl(RequestOptions options) {
    final extraTtl = options.extra['cache_ttl'];
    if (extraTtl is Duration) return extraTtl;
    if (extraTtl is int) return Duration(seconds: extraTtl);
    return defaultTtl;
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!_isCacheable(options)) {
      return handler.next(options);
    }

    final key = _generateKey(options);
    final entry = _cache[key];

    if (entry != null && !entry.isExpired) {
      final response = Response(
        requestOptions: options,
        data: entry.data,
        statusCode: entry.statusCode,
        headers: entry.headers,
        extra: {
          ...options.extra,
          'from_cache': true,
          'cache_hit': true,
        },
      );
      return handler.resolve(response);
    }

    return handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final method = response.requestOptions.method.toUpperCase();

    // Mutations invalidate cached queries to prevent stale business state
    if (method == 'POST' ||
        method == 'PUT' ||
        method == 'PATCH' ||
        method == 'DELETE') {
      final status = response.statusCode;
      if (status != null && status >= 200 && status < 300) {
        _cache.clear();
      }
      return handler.next(response);
    }

    if (_isCacheable(response.requestOptions) && response.statusCode == 200) {
      final key = _generateKey(response.requestOptions);
      if (_cache.length >= maxCacheEntries) {
        _cache.remove(_cache.keys.first);
      }
      _cache[key] = HttpCacheEntry(
        data: response.data,
        headers: response.headers,
        statusCode: response.statusCode ?? 200,
        cachedAt: DateTime.now(),
        ttl: _getTtl(response.requestOptions),
      );
    }

    return handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final isNetworkError =
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError ||
        err.error is SocketException;

    if (isNetworkError && err.requestOptions.method.toUpperCase() == 'GET') {
      final key = _generateKey(err.requestOptions);
      final entry = _cache[key];
      if (entry != null) {
        final fallbackResponse = Response(
          requestOptions: err.requestOptions,
          data: entry.data,
          statusCode: entry.statusCode,
          headers: entry.headers,
          extra: {
            ...err.requestOptions.extra,
            'from_cache': true,
            'offline_fallback': true,
          },
        );
        return handler.resolve(fallbackResponse);
      }
    }

    return handler.next(err);
  }
}
