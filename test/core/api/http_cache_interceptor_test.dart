import 'dart:io';
import 'dart:typed_data';
import 'package:akademihub_mob/core/api/http_cache_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

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
  group('HttpCacheInterceptor', () {
    late Dio dio;
    late HttpCacheInterceptor interceptor;
    late int networkCallCount;

    setUp(() {
      networkCallCount = 0;
      interceptor = HttpCacheInterceptor();
      dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
      dio.interceptors.add(interceptor);

      dio.httpClientAdapter = _TestAdapter((options) async {
        networkCallCount++;
        return ResponseBody.fromString(
          '{"success":true,"call":$networkCallCount}',
          200,
          headers: {
            'content-type': ['application/json'],
          },
        );
      });
    });

    test('caches GET requests within TTL and returns cached response', () async {
      final res1 = await dio.get('/jadwal');
      expect(res1.data, contains('"call":1'));
      expect(networkCallCount, 1);

      final res2 = await dio.get('/jadwal');
      expect(res2.data, contains('"call":1'));
      expect(res2.extra['from_cache'], isTrue);
      expect(res2.extra['cache_hit'], isTrue);
      expect(networkCallCount, 1);
    });

    test('bypasses cache when no_cache extra is passed', () async {
      await dio.get('/jadwal');
      expect(networkCallCount, 1);

      await dio.get('/jadwal', options: Options(extra: {'no_cache': true}));
      expect(networkCallCount, 2);
    });

    test('POST mutations invalidate cached queries', () async {
      await dio.get('/jadwal');
      expect(networkCallCount, 1);

      await dio.post('/jadwal', data: {'subject': 'Math'});
      expect(interceptor.entryCount, 0);

      await dio.get('/jadwal');
      expect(networkCallCount, 3);
    });

    test('provides offline fallback when network is down for previously cached GET', () async {
      await dio.get('/soal');
      expect(networkCallCount, 1);

      dio.httpClientAdapter = _TestAdapter((options) async {
        networkCallCount++;
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
          error: const SocketException('No signal'),
        );
      });

      final fallbackRes = await dio.get('/soal');
      expect(fallbackRes.extra['from_cache'], isTrue);
      expect(fallbackRes.extra['offline_fallback'], isTrue);
      expect(fallbackRes.data, contains('"call":1'));
    });
  });
}
