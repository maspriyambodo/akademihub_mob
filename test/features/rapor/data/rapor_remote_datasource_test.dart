import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:akademihub_mob/features/rapor/data/datasources/rapor_remote_datasource.dart';

void main() {
  group('RaporRemoteDataSource', () {
    late _RecordingAdapter adapter;
    late RaporRemoteDataSource source;

    setUp(() {
      adapter = _RecordingAdapter();
      source = RaporRemoteDataSourceImpl(Dio()..httpClientAdapter = adapter);
    });

    test('create sends backend contract fields', () async {
      await source.createRapor(
        siswaId: 2,
        semester: 3,
        sakit: 1,
        details: [
          {'mst_mapel_id': 4, 'nilai_pengetahuan': 87.5},
        ],
      );

      expect(adapter.method, 'POST');
      expect(adapter.path, '/akademik/rapor');
      expect(adapter.data, {
        'mst_siswa_id': 2,
        'semester': 3,
        'sakit': 1,
        'details': [
          {'mst_mapel_id': 4, 'nilai_pengetahuan': 87.5},
        ],
      });
    });

    test('update omits unchanged fields', () async {
      await source.updateRapor(id: 7, catatanWali: 'Baik');

      expect(adapter.method, 'PUT');
      expect(adapter.path, '/akademik/rapor/7');
      expect(adapter.data, {'catatan_wali': 'Baik'});
    });

    test('delete targets rapor record', () async {
      await source.deleteRapor(7);

      expect(adapter.method, 'DELETE');
      expect(adapter.path, '/akademik/rapor/7');
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
      '{"data":{"id":7}}',
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }
}
