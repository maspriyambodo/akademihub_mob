import 'dart:typed_data';
import 'package:akademihub_mob/features/ppdb/data/ppdb_public_api.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _Adapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions) handler;
  _Adapter(this.handler);
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancelFuture,
  ) => handler(options);
  @override
  void close({bool force = false}) {}
}

void main() {
  test('PPDB public API uses read-only public endpoints', () async {
    final dio = Dio();
    final paths = <String>[];
    dio.httpClientAdapter = _Adapter((options) async {
      paths.add('${options.method} ${options.path}');
      return ResponseBody.fromString(
        '{"data":[{"id":1,"nama_sekolah":"Sekolah"}]}',
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    });
    final api = PpdbPublicApi(dio);
    await api.schools();
    await api.activeWaves(1);
    await api.applicationStatus('PPDB/1');
    expect(paths, [
      'GET /ppdb/public/sekolah',
      'GET /ppdb/public/gelombang/1/active',
      'GET /ppdb/public/status/PPDB%2F1',
    ]);
    expect(paths.every((path) => path.startsWith('GET ')), isTrue);
  });
}
