import 'package:akademihub_mob/features/materi/data/datasources/materi_remote_datasource.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MateriRemoteDataSource', () {
    late _RecordingAdapter adapter;
    late MateriRemoteDataSource source;

    setUp(() {
      adapter = _RecordingAdapter();
      source = MateriRemoteDataSourceImpl(Dio()..httpClientAdapter = adapter);
    });

    test('create sends backend contract fields', () async {
      await source.createMateri(
        guruMapelId: 2,
        judul: 'Pecahan',
        deskripsi: 'Dasar pecahan',
        status: 1,
      );

      expect(adapter.method, 'POST');
      expect(adapter.path, '/akademik/materi');
      expect(adapter.data, {
        'mst_guru_mapel_id': 2,
        'judul': 'Pecahan',
        'deskripsi': 'Dasar pecahan',
        'status': 1,
      });
    });

    test('update sends only changed fields', () async {
      await source.updateMateri(id: 7, judul: 'Pecahan lanjut');

      expect(adapter.method, 'PUT');
      expect(adapter.path, '/akademik/materi/7');
      expect(adapter.data, {'judul': 'Pecahan lanjut'});
    });

    test('delete targets materi record', () async {
      await source.deleteMateri(7);

      expect(adapter.method, 'DELETE');
      expect(adapter.path, '/akademik/materi/7');
    });
  });
}

class _RecordingAdapter implements HttpClientAdapter {
  String? method;
  String? path;
  Object? data;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    method = options.method;
    path = options.path;
    data = options.data;
    return ResponseBody.fromString(
      '{"data":{"id":7,"judul":"Pecahan"}}',
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }
}
