import 'package:akademihub_mob/features/absensi/data/datasources/absensi_remote_datasource.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:akademihub_mob/features/absensi/domain/entities/attendance_location.dart';

void main() {
  test('self check-in mengirim lokasi segar ke endpoint canonical', () async {
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

    await AbsensiRemoteDataSourceImpl(dio).checkIn(
      AttendanceLocation(
        latitude: -6.2,
        longitude: 106.8,
        accuracyMeter: 12.5,
        capturedAt: DateTime.utc(2026, 8, 16, 0, 30),
      ),
    );

    expect(captured?.method, 'POST');
    expect(captured?.path, '/akademik/absensi-siswa/check-in');
    expect(captured?.data, {
      'latitude': -6.2,
      'longitude': 106.8,
      'accuracy_meter': 12.5,
      'captured_at': '2026-08-16T00:30:00.000Z',
    });
    expect(captured?.queryParameters, isEmpty);
  });

  test('self check-out memakai endpoint canonical', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://school.test/api/v1'));
    RequestOptions? captured;
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          captured = options;
          handler.resolve(Response(requestOptions: options, statusCode: 200));
        },
      ),
    );
    final location = AttendanceLocation(
      latitude: -6.2,
      longitude: 106.8,
      accuracyMeter: 8,
      capturedAt: DateTime.utc(2026, 8, 16, 8),
    );

    await AbsensiRemoteDataSourceImpl(dio).checkOut(location);

    expect(captured?.method, 'POST');
    expect(captured?.path, '/akademik/absensi-siswa/check-out');
    expect(captured?.data, location.toJson());
  });
}
