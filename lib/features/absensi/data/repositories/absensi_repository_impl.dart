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
  Future<Result<void>> checkIn(AttendanceLocation location) async {
    try {
      await _remote.checkIn(location);
      return success(null);
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    }
  }

  @override
  Future<Result<void>> checkOut(AttendanceLocation location) async {
    try {
      await _remote.checkOut(location);
      return success(null);
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    } on Object catch (e) {
      return fail(ServerFailure(_locationMessage(e)));
    }
  }

  @override
  Future<Result<AbsensiSiswaEntity?>> getCurrentAttendance() async {
    try {
      return success((await _remote.getCurrentAttendance())?.toEntity());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    } on Object catch (e) {
      return fail(ServerFailure(_locationMessage(e)));
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
    return ServerFailure(e.message);
  }

  String _locationMessage(Object error) => switch (error) {
    LocationServiceDisabledException() =>
      'Aktifkan layanan lokasi lalu coba lagi',
    PermissionDeniedException(:final message) => message,
    LocationAccuracyException(:final message) => message,
    _ => 'Gagal mengambil lokasi terbaru',
  };
}
