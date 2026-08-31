import 'dart:typed_data';

import 'package:akademihub_mob/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _Adapter implements HttpClientAdapter {
  RequestOptions? request;
  String responseBody = '{"data":{"access_token":"token","user":{}}}';

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options;
    return ResponseBody.fromString(
      responseBody,
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
  test('login sends only username and password', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'));
    final adapter = _Adapter();
    dio.httpClientAdapter = adapter;

    await AuthRemoteDataSourceImpl(dio).login('guru01', 'secret123');

    expect(adapter.request?.path, '/auth/login');
    expect(adapter.request?.method, 'POST');
    expect(adapter.request?.data, {
      'username': 'guru01',
      'password': 'secret123',
    });
  });

  test('current user parses hydrated profile from wrapped response', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'));
    final adapter = _Adapter()
      ..responseBody = '''
        {"data":{"id":10,"name":"Siswa","email":"siswa@example.test",
        "role":"SISWA","profile":{"id":62}}}
      ''';
    dio.httpClientAdapter = adapter;

    final user = await AuthRemoteDataSourceImpl(dio).getCurrentUser();

    expect(adapter.request?.path, '/auth/me');
    expect(user.profile?['id'], 62);
  });
}
