import 'package:dio/dio.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../datasources/absensi_remote_datasource.dart';
import '../../domain/entities/absensi_siswa_entity.dart';
import '../../domain/entities/absensi_guru_entity.dart';
import '../../domain/repositories/absensi_repository.dart';
import '../../domain/entities/attendance_location.dart';

class AbsensiRepositoryImpl implements AbsensiRepository {
  final AbsensiRemoteDataSource _remote;

  const AbsensiRepositoryImpl(this._remote);

  @override
  Future<Result<AbsensiSiswaEntity>> checkIn(
    AttendanceLocation location,
  ) async {
    try {
      return success((await _remote.checkIn(location)).toEntity());
    } on DioException catch (e) {
      return fail(mapAbsensiMutationFailure(e));
    } on FormatException catch (e) {
      return fail(ServerFailure(e.message));
    }
  }

  @override
  Future<Result<AbsensiSiswaEntity>> checkOut(
    AttendanceLocation location,
  ) async {
    try {
      return success((await _remote.checkOut(location)).toEntity());
    } on DioException catch (e) {
      return fail(mapAbsensiMutationFailure(e));
    } on FormatException catch (e) {
      return fail(ServerFailure(e.message));
    }
  }

  @override
  Future<Result<List<AbsensiSiswaEntity>>> getAbsensiSiswaList(
    int siswaId,
  ) async {
    try {
      final models = await _remote.getAbsensiSiswaList(siswaId);
      return success(models.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    }
  }

  @override
  Future<Result<List<AbsensiGuruEntity>>> getAbsensiGuruList(int guruId) async {
    try {
      final models = await _remote.getAbsensiGuruList(guruId);
      return success(models.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    }
  }

  @override
  Future<Result<List<AbsensiSiswaEntity>>> getAbsensiSiswaGeneral({
    String? tanggalFrom,
    String? tanggalTo,
  }) async {
    try {
      final models = await _remote.getAbsensiSiswaGeneral(
        tanggalFrom: tanggalFrom,
        tanggalTo: tanggalTo,
      );
      return success(models.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    }
  }

  Failure _map(AppException e) {
    if (e is NetworkException) return NetworkFailure(e.message);
    if (e is AuthException) return AuthFailure(e.message);
    if (e is ForbiddenException) return ForbiddenFailure(e.message);
    if (e is ValidationException) {
      return ValidationFailure(e.message, errors: e.errors);
    }
    if (e is NotFoundException) return NotFoundFailure(e.message);
    return ServerFailure(e.message);
  }
}

Failure mapAbsensiMutationFailure(DioException error) {
  if (error.type != DioExceptionType.badResponse) {
    return _mapException(mapDioException(error));
  }

  final raw = error.response?.data;
  final body = raw is Map ? raw : const {};
  final code = body['code']?.toString();
  final rawDetails = body['data'];
  final details = rawDetails is Map
      ? rawDetails.map((key, value) => MapEntry(key.toString(), value))
      : <String, dynamic>{};
  final message = _absensiMessage(code, details);
  if (code != null && message != null) {
    return AbsensiFailure(message, code: code, details: details);
  }
  return _mapException(mapDioException(error));
}

String? _absensiMessage(String? code, Map<String, dynamic> details) {
  switch (code) {
    case 'unauthenticated':
      return 'Sesi telah berakhir. Silakan masuk kembali.';
    case 'student_only':
      return 'Absensi mandiri hanya tersedia untuk siswa aktif.';
    case 'check_in_required':
      return 'Check-in belum tercatat. Muat ulang data lalu coba check-out kembali.';
    case 'attendance_already_finalized':
      return 'Absensi hari ini sudah diselesaikan oleh petugas.';
    case 'too_early_to_check_out':
      final allowedAt = details['allowed_at']?.toString();
      final timezone = details['timezone']?.toString();
      if (allowedAt != null && allowedAt.isNotEmpty) {
        return 'Check-out tersedia pukul $allowedAt${timezone == null || timezone.isEmpty ? '' : ' ($timezone)'}.';
      }
      return 'Waktu check-out belum dimulai.';
    case 'outside_school_area':
      return 'Perangkat berada di luar area sekolah.';
    case 'location_accuracy_too_low':
      return 'Akurasi lokasi belum memadai. Coba lagi di area terbuka.';
    case 'stale_location':
      return 'Lokasi sudah kedaluwarsa. Ambil posisi baru lalu coba lagi.';
    case 'attendance_settings_unavailable':
      return 'Konfigurasi absensi sekolah belum tersedia. Hubungi petugas sekolah.';
    case 'attendance_shift_unavailable':
      return 'Kelas atau shift absensi belum siap. Hubungi petugas sekolah.';
  }
  return null;
}

Failure _mapException(AppException e) {
  if (e is NetworkException) return NetworkFailure(e.message);
  if (e is AuthException) return AuthFailure(e.message);
  if (e is ForbiddenException) return ForbiddenFailure(e.message);
  if (e is ValidationException) {
    return ValidationFailure(e.message, errors: e.errors);
  }
  if (e is NotFoundException) return NotFoundFailure(e.message);
  return ServerFailure(e.message);
}
