import 'package:akademihub_mob/features/absensi/data/datasources/absensi_remote_datasource.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('self check-in memakai endpoint canonical tanpa body client', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://school.test/api/v1'));
    RequestOptions? captured;
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          captured = options;
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'success': true,
                'message': 'Check-in berhasil',
                'data': {
                  'id': 91,
                  'mst_siswa_id': 7,
                  'tanggal': '2026-08-16',
                  'status': 1,
                },
              },
            ),
          );
        },
      ),
    );

    await AbsensiRemoteDataSourceImpl(dio).checkIn();

    expect(captured?.method, 'POST');
    expect(captured?.path, '/akademik/absensi-siswa/check-in');
    expect(captured?.data, isNull);
    expect(captured?.queryParameters, isEmpty);
  });
}
