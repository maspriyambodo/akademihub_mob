import 'dart:typed_data';
import 'package:akademihub_mob/features/tv/data/datasources/tv_remote_datasource.dart';
import 'package:akademihub_mob/features/tv/domain/entities/tv_pairing_session.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _MockHttpClientAdapter implements HttpClientAdapter {
  RequestOptions? request;
  int statusCode = 200;
  String responseBody = '{}';
  Map<String, List<String>> headers = {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  };

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options;
    return ResponseBody.fromString(responseBody, statusCode, headers: headers);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late Dio dio;
  late _MockHttpClientAdapter adapter;
  late TvRemoteDataSource dataSource;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'https://api.akademihub.id/api/v1'));
    adapter = _MockHttpClientAdapter();
    dio.httpClientAdapter = adapter;
    dataSource = TvRemoteDataSourceImpl(dio);
  });

  group('TvRemoteDataSource', () {
    test(
      'createPairingSession sends POST /tv/pairing/sessions with correct body',
      () async {
        adapter.statusCode = 201;
        adapter.responseBody = '''
      {
        "success": true,
        "data": {
          "session_id": "sess-uuid-1",
          "user_code": "AB7K9Q",
          "verification_url": "https://app.akademihub.id/tv-pair",
          "expires_at": "2026-09-05T14:15:00Z",
          "poll_interval_seconds": 5
        }
      }
      ''';

        final result = await dataSource.createPairingSession(
          installationId: 'inst-uuid-1',
          deviceName: 'Lobby TV',
          appVersion: '1.0.0+1',
        );

        expect(adapter.request?.path, '/tv/pairing/sessions');
        expect(adapter.request?.method, 'POST');
        expect(adapter.request?.data, {
          'installation_id': 'inst-uuid-1',
          'device_name': 'Lobby TV',
          'app_version': '1.0.0+1',
        });
        expect(result.sessionId, 'sess-uuid-1');
        expect(result.userCode, 'AB7K9Q');
      },
    );

    test(
      'getPairingStatus sends GET /tv/pairing/sessions/{id} with X-TV-Installation-ID',
      () async {
        adapter.statusCode = 200;
        adapter.responseBody = '''
      {
        "success": true,
        "data": {
          "status": "approved",
          "device_token": "raw-token-42",
          "device": {
            "id": 10,
            "name": "TV Kelas X",
            "mode": "classroom"
          }
        }
      }
      ''';

        final result = await dataSource.getPairingStatus(
          sessionId: 'sess-uuid-1',
          installationId: 'inst-uuid-1',
        );

        expect(adapter.request?.path, '/tv/pairing/sessions/sess-uuid-1');
        expect(adapter.request?.method, 'GET');
        expect(adapter.request?.headers['X-TV-Installation-ID'], 'inst-uuid-1');
        expect(result.state, TvPairingState.approved);
        expect(result.deviceToken, 'raw-token-42');
        expect(result.deviceId, 10);
      },
    );

    test(
      'unpairCurrent sends DELETE /tv/devices/current with Bearer token',
      () async {
        adapter.statusCode = 200;
        adapter.responseBody = '{"success": true}';

        await dataSource.unpairCurrent(deviceToken: 'token-abc');

        expect(adapter.request?.path, '/tv/devices/current');
        expect(adapter.request?.method, 'DELETE');
        expect(adapter.request?.headers['Authorization'], 'Bearer token-abc');
      },
    );

    test(
      'getSnapshot sends GET /tv/snapshot with Bearer and optional ETag',
      () async {
        adapter.statusCode = 304;
        adapter.responseBody = '';

        final response = await dataSource.getSnapshot(
          deviceToken: 'token-xyz',
          etag: '"etag-12345"',
        );

        expect(adapter.request?.path, '/tv/snapshot');
        expect(adapter.request?.method, 'GET');
        expect(adapter.request?.headers['Authorization'], 'Bearer token-xyz');
        expect(adapter.request?.headers['If-None-Match'], '"etag-12345"');
        expect(response.statusCode, 304);
      },
    );
  });
}
