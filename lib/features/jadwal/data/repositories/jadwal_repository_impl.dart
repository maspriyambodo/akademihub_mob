import 'package:dio/dio.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../datasources/jadwal_remote_datasource.dart';
import '../../domain/entities/jadwal_pelajaran_entity.dart';
import '../../domain/repositories/jadwal_repository.dart';

class JadwalRepositoryImpl implements JadwalRepository {
  final JadwalRemoteDataSource _remote;

  const JadwalRepositoryImpl(this._remote);

  @override
  Future<Result<List<JadwalPelajaranEntity>>> getJadwalByKelas(
    int kelasId,
  ) async {
    try {
      final models = await _remote.getJadwalByKelas(kelasId);
      return success(models.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    }
  }

  @override
  Future<Result<List<JadwalPelajaranEntity>>> getJadwalByKelasHari(
    int kelasId,
    String hari,
  ) async {
    try {
      final models = await _remote.getJadwalByKelasHari(kelasId, hari);
      return success(models.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    }
  }

  @override
  Future<Result<List<JadwalPelajaranEntity>>> getJadwalList({
    int? kelasId,
    String? hari,
  }) async {
    try {
      final models = await _remote.getJadwalList(kelasId: kelasId, hari: hari);
      return success(models.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    }
  }

  Failure _map(AppException e) {
    if (e is NetworkException) return NetworkFailure(e.message);
    if (e is AuthException) return AuthFailure(e.message);
    return ServerFailure(e.message);
  }
}
