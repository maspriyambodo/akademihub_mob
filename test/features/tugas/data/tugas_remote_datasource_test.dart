import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:akademihub_mob/features/tugas/data/datasources/tugas_remote_datasource.dart';

void main() {
  group('TugasRemoteDataSource', () {
    late _RecordingAdapter adapter;
    late TugasRemoteDataSource source;

    setUp(() {
      adapter = _RecordingAdapter();
      source = TugasRemoteDataSourceImpl(Dio()..httpClientAdapter = adapter);
    });

    test('create sends backend contract fields', () async {
      await source.createTugas(
        guruMapelId: 2,
        kelasId: 3,
        judul: 'Essay Bab 1',
        tenggatWaktu: '2026-08-30 10:00:00',
        deskripsi: 'Kerjakan mandiri',
        status: 1,
      );

      expect(adapter.method, 'POST');
      expect(adapter.path, '/akademik/tugas');
      expect(adapter.data, {
        'mst_guru_mapel_id': 2,
        'mst_kelas_id': 3,
        'judul': 'Essay Bab 1',
        'tenggat_waktu': '2026-08-30 10:00:00',
        'deskripsi': 'Kerjakan mandiri',
        'status': 1,
      });
    });

    test('update omits unchanged fields', () async {
      await source.updateTugas(id: 7, judul: 'Judul baru');

      expect(adapter.method, 'PUT');
      expect(adapter.path, '/akademik/tugas/7');
      expect(adapter.data, {'judul': 'Judul baru'});
    });

    test('delete targets tugas record', () async {
      await source.deleteTugas(7);

      expect(adapter.method, 'DELETE');
      expect(adapter.path, '/akademik/tugas/7');
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
      '{"data":{"id":7,"judul":"Essay Bab 1"}}',
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }
}
