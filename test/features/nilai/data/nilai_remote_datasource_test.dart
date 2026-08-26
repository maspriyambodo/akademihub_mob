import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:akademihub_mob/features/nilai/data/datasources/nilai_remote_datasource.dart';

void main() {
  group('NilaiRemoteDataSource', () {
    late _RecordingAdapter adapter;
    late NilaiRemoteDataSource source;

    setUp(() {
      adapter = _RecordingAdapter();
      source = NilaiRemoteDataSourceImpl(Dio()..httpClientAdapter = adapter);
    });

    test('create sends backend contract fields', () async {
      await source.createNilai(
        siswaId: 2,
        ujianId: 3,
        nilai: 87.5,
        keterangan: 'Baik',
      );

      expect(adapter.method, 'POST');
      expect(adapter.path, '/akademik/nilai');
      expect(adapter.data, {
        'mst_siswa_id': 2,
        'trx_ujian_id': 3,
        'nilai': 87.5,
        'keterangan': 'Baik',
      });
    });

    test('update omits unchanged fields', () async {
      await source.updateNilai(id: 7, nilai: 90);

      expect(adapter.method, 'PUT');
      expect(adapter.path, '/akademik/nilai/7');
      expect(adapter.data, {'nilai': 90.0});
    });

    test('delete targets grade record', () async {
      await source.deleteNilai(7);

      expect(adapter.method, 'DELETE');
      expect(adapter.path, '/akademik/nilai/7');
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
      '{"data":{"id":7,"nilai":"90.00"}}',
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }
}
