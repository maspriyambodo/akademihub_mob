import 'dart:async';
import 'dart:typed_data';
import 'package:akademihub_mob/core/api/api_client.dart';
import 'package:akademihub_mob/core/config/app_config.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeStorage extends FlutterSecureStorage {
  final Map<String, String> _data = {};

  _FakeStorage([Map<String, String>? initial]) {
    if (initial != null) _data.addAll(initial);
  }

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _data[key];
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      _data.remove(key);
    } else {
      _data[key] = value;
    }
  }

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _data.remove(key);
  }
}

class _TestAdapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions options) onRequest;

  _TestAdapter(this.onRequest);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return onRequest(options);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('uses fixed API gateway', () {
    final client = ApiClient(const FlutterSecureStorage());
    expect(client.dio.options.baseUrl, AppConfig.apiBaseUrl);
  });

  group('MOB-AUTH-01 Single-Flight Refresh Token', () {
    late _FakeStorage storage;
    late ApiClient apiClient;

    setUp(() {
      storage = _FakeStorage({
        AppConfig.tokenKey: 'old-access-token',
        AppConfig.refreshTokenKey: 'old-refresh-token',
      });
      apiClient = ApiClient(storage);
    });

    test(
      'parallel 401 errors trigger single refresh request and retry both',
      () async {
        int refreshCalls = 0;
        final retriedHeaders = <String>[];

        apiClient.dio.httpClientAdapter = _TestAdapter((options) async {
          if (options.path.contains('/auth/refresh')) {
            refreshCalls++;
            // Delay to simulate async network roundtrip during concurrent requests
            await Future.delayed(const Duration(milliseconds: 50));
            final body =
                '{"success":true,"data":{"access_token":"new-access-token","refresh_token":"new-refresh-token"}}';
            return ResponseBody.fromString(
              body,
              200,
              headers: {
                'content-type': ['application/json'],
              },
            );
          }

          final authHeader = options.headers['Authorization'] as String?;
          if (authHeader == 'Bearer new-access-token') {
            retriedHeaders.add(authHeader!);
            return ResponseBody.fromString(
              '{"success":true,"data":"ok"}',
              200,
              headers: {
                'content-type': ['application/json'],
              },
            );
          }

          return ResponseBody.fromString(
            '{"error":"unauthorized"}',
            401,
            headers: {
              'content-type': ['application/json'],
            },
          );
        });

        final future1 = apiClient.dio.get('/profile');
        final future2 = apiClient.dio.get('/dashboard');

        final results = await Future.wait([future1, future2]);

        expect(refreshCalls, 1);
        expect(results.length, 2);
        expect(retriedHeaders.length, 2);
        expect(await storage.read(key: AppConfig.tokenKey), 'new-access-token');
        expect(
          await storage.read(key: AppConfig.refreshTokenKey),
          'new-refresh-token',
        );
      },
    );

    test(
      'refresh failure clears token storage and does not retry infinitely',
      () async {
        int refreshCalls = 0;

        apiClient.dio.httpClientAdapter = _TestAdapter((options) async {
          if (options.path.contains('/auth/refresh')) {
            refreshCalls++;
            return ResponseBody.fromString(
              '{"error":"invalid_token"}',
              401,
              headers: {
                'content-type': ['application/json'],
              },
            );
          }
          return ResponseBody.fromString(
            '{"error":"unauthorized"}',
            401,
            headers: {
              'content-type': ['application/json'],
            },
          );
        });

        await expectLater(
          apiClient.dio.get('/profile'),
          throwsA(isA<DioException>()),
        );

        expect(refreshCalls, 1);
        expect(await storage.read(key: AppConfig.tokenKey), isNull);
        expect(await storage.read(key: AppConfig.refreshTokenKey), isNull);
      },
    );

    test('excluded auth endpoints do not trigger refresh', () async {
      int refreshCalls = 0;

      apiClient.dio.httpClientAdapter = _TestAdapter((options) async {
        if (options.extra['is_retry'] == true &&
            options.path.contains('/auth/refresh')) {
          refreshCalls++;
          return ResponseBody.fromString('{"success":true}', 200);
        }
        return ResponseBody.fromString('{"error":"unauthorized"}', 401);
      });

      for (final endpoint in [
        '/auth/login',
        '/auth/register',
        '/auth/refresh',
        '/auth/logout',
      ]) {
        await expectLater(
          apiClient.dio.post(endpoint),
          throwsA(isA<DioException>()),
        );
      }

      expect(refreshCalls, 0);
    });

    test(
      'retry that receives 401 again stops, clears token storage, and does not loop',
      () async {
        int refreshCalls = 0;

        apiClient.dio.httpClientAdapter = _TestAdapter((options) async {
          if (options.path.contains('/auth/refresh')) {
            refreshCalls++;
            return ResponseBody.fromString(
              '{"success":true,"data":{"access_token":"bad-access-token","refresh_token":"bad-refresh-token"}}',
              200,
              headers: {
                'content-type': ['application/json'],
              },
            );
          }
          // Retried request still gets 401
          return ResponseBody.fromString(
            '{"error":"unauthorized"}',
            401,
            headers: {
              'content-type': ['application/json'],
            },
          );
        });

        await expectLater(
          apiClient.dio.get('/profile'),
          throwsA(isA<DioException>()),
        );

        expect(refreshCalls, 1);
        expect(await storage.read(key: AppConfig.tokenKey), isNull);
        expect(await storage.read(key: AppConfig.refreshTokenKey), isNull);
      },
    );

    test('response 403 Forbidden does not trigger token refresh', () async {
      int refreshCalls = 0;

      apiClient.dio.httpClientAdapter = _TestAdapter((options) async {
        if (options.path.contains('/auth/refresh')) {
          refreshCalls++;
          return ResponseBody.fromString('{"success":true}', 200);
        }
        return ResponseBody.fromString(
          '{"error":"forbidden"}',
          403,
          headers: {
            'content-type': ['application/json'],
          },
        );
      });

      await expectLater(
        apiClient.dio.get('/admin/analytics'),
        throwsA(isA<DioException>()),
      );

      expect(refreshCalls, 0);
      expect(await storage.read(key: AppConfig.tokenKey), 'old-access-token');
    });

    test('write requests refresh but never replay automatically', () async {
      int refreshCalls = 0;
      final writes = <String, int>{};

      apiClient.dio.httpClientAdapter = _TestAdapter((options) async {
        if (options.path == '/auth/refresh') {
          refreshCalls++;
          return ResponseBody.fromString(
            '{"data":{"access_token":"new-access-token"}}',
            200,
            headers: {
              'content-type': ['application/json'],
            },
          );
        }
        writes.update(options.method, (count) => count + 1, ifAbsent: () => 1);
        return ResponseBody.fromString(
          '{"message":"unauthorized"}',
          401,
          headers: {
            'content-type': ['application/json'],
          },
        );
      });

      for (final method in ['POST', 'PUT', 'PATCH', 'DELETE']) {
        await expectLater(
          apiClient.dio.request('/resource', options: Options(method: method)),
          throwsA(isA<DioException>()),
        );
      }

      expect(refreshCalls, 4);
      expect(writes, {'POST': 1, 'PUT': 1, 'PATCH': 1, 'DELETE': 1});
    });

    test('matching gateway origin attaches stored token', () async {
      final origin = AppConfig.extractOrigin(AppConfig.apiBaseUrl)!;
      await storage.write(key: AppConfig.tokenOriginKey, value: origin);
      String? authorization;
      apiClient.dio.httpClientAdapter = _TestAdapter((options) async {
        authorization = options.headers['Authorization'] as String?;
        return ResponseBody.fromString('{"data":"ok"}', 200);
      });

      await apiClient.dio.get('/profile');

      expect(authorization, 'Bearer old-access-token');
      expect(await storage.read(key: AppConfig.tokenKey), 'old-access-token');
    });
  });
}
