import 'dart:typed_data';

import 'package:akademihub_mob/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _Adapter implements HttpClientAdapter {
  RequestOptions? request;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options;
    return ResponseBody.fromString(
      '{"data":{"access_token":"token","user":{}}}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('login sends only identifier and password', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'));
    final adapter = _Adapter();
    dio.httpClientAdapter = adapter;

    await AuthRemoteDataSourceImpl(dio).login('guru01', 'secret123');

    expect(adapter.request?.path, '/auth/login');
    expect(adapter.request?.method, 'POST');
    expect(adapter.request?.data, {
      'identifier': 'guru01',
      'password': 'secret123',
    });
  });
}
