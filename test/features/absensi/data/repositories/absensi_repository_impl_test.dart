import 'package:akademihub_mob/core/error/failures.dart';
import 'package:akademihub_mob/features/absensi/data/repositories/absensi_repository_impl.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  DioException responseError(String code, {Map<String, dynamic>? data}) {
    final request = RequestOptions(path: '/absensi');
    return DioException(
      requestOptions: request,
      response: Response(
        requestOptions: request,
        statusCode: code == 'unauthenticated' ? 401 : 422,
        data: {'success': false, 'code': code, 'message': code, 'data': data},
      ),
      type: DioExceptionType.badResponse,
    );
  }

  test('memetakan seluruh code error absensi ke pesan aman', () {
    const expected = {
      'unauthenticated': 'Sesi telah berakhir',
      'student_only': 'hanya tersedia untuk siswa aktif',
      'check_in_required': 'Check-in belum tercatat',
      'attendance_already_finalized': 'sudah diselesaikan oleh petugas',
      'too_early_to_check_out': 'Waktu check-out belum dimulai',
      'outside_school_area': 'di luar area sekolah',
      'location_accuracy_too_low': 'Coba lagi di area terbuka',
      'stale_location': 'Ambil posisi baru',
      'attendance_settings_unavailable': 'Hubungi petugas sekolah',
      'attendance_shift_unavailable': 'Hubungi petugas sekolah',
    };

    for (final entry in expected.entries) {
      final failure = mapAbsensiMutationFailure(responseError(entry.key));
      expect(failure, isA<AbsensiFailure>(), reason: entry.key);
      expect(failure.message, contains(entry.value), reason: entry.key);
      expect((failure as AbsensiFailure).code, entry.key);
    }
  });

  test('too_early_to_check_out menampilkan allowed_at dan timezone', () {
    final failure =
        mapAbsensiMutationFailure(
              responseError(
                'too_early_to_check_out',
                data: {'allowed_at': '15:00:00', 'timezone': 'Asia/Jakarta'},
              ),
            )
            as AbsensiFailure;

    expect(
      failure.message,
      'Check-out tersedia pukul 15:00:00 (Asia/Jakarta).',
    );
    expect(failure.details['allowed_at'], '15:00:00');
  });

  test('code asing memakai mapper HTTP umum', () {
    final failure = mapAbsensiMutationFailure(responseError('future_code'));
    expect(failure, isA<ValidationFailure>());
  });
}
