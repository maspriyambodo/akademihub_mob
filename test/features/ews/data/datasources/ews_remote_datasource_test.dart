import 'package:akademihub_mob/features/ews/data/datasources/ews_remote_datasource.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Dio dio;
  late EwsRemoteDataSourceImpl dataSource;

  setUp(() {
    dio = Dio();
    dataSource = EwsRemoteDataSourceImpl(dio);
  });

  test('getAlertDetail fetches canonical GET /ews/{id} endpoint', () async {
    dio.httpClientAdapter = _MockAdapter((options) {
      if (options.path == '/ews/105' && options.method == 'GET') {
        return ResponseBody.fromString(
          '{"success":true,"data":{"id":105,"mst_siswa_id":12,"kategori":"absensi","level":2,"pesan":"Absen 3 hari","is_resolved":false}}',
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      }
      return ResponseBody.fromString('Not found', 404);
    });

    final alert = await dataSource.getAlertDetail(105);
    expect(alert.id, 105);
    expect(alert.siswaId, 12);
    expect(alert.kategori, 'absensi');
    expect(alert.level, 2);
  });

  test('getAlertDetail throws DioException on 404 or 403 response', () async {
    dio.httpClientAdapter = _MockAdapter((options) {
      return ResponseBody.fromString(
        '{"success":false,"message":"Alert not found"}',
        404,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    });

    expect(() => dataSource.getAlertDetail(999), throwsA(isA<DioException>()));
  });
}

class _MockAdapter implements HttpClientAdapter {
  final ResponseBody Function(RequestOptions options) _handler;

  _MockAdapter(this._handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return _handler(options);
  }

  @override
  void close({bool force = false}) {}
}
