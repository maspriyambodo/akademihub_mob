import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/log_akses_materi_entity.dart';
import '../../domain/entities/materi_entity.dart';
import '../../domain/repositories/materi_repository.dart';
import '../datasources/materi_remote_datasource.dart';

class MateriRepositoryImpl implements MateriRepository {
  final MateriRemoteDataSource _remote;

  const MateriRepositoryImpl(this._remote);

  @override
  Future<Result<List<MateriEntity>>> getMateriList({int? status}) async {
    try {
      final models = await _remote.getMateriList(status: status);
      return success(models.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    }
  }

  @override
  Future<Result<MateriEntity>> getMateriDetail(int id) async {
    try {
      final model = await _remote.getMateriDetail(id);
      return success(model.toEntity());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    }
  }

  @override
  Future<Result<List<MateriEntity>>> getMateriByGuruMapel(
    int guruMapelId,
  ) async {
    try {
      final models = await _remote.getMateriByGuruMapel(guruMapelId);
      return success(models.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    }
  }

  @override
  Future<Result<List<MateriPopulerEntity>>> getMateriPopuler({
    int limit = 5,
  }) async {
    try {
      final models = await _remote.getMateriPopuler(limit: limit);
      return success(models.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    }
  }

  @override
  Future<Result<MateriEntity>> createMateri({
    required int guruMapelId,
    required String judul,
    String? deskripsi,
    String? fileMateri,
    String? linkVideo,
    int? status,
  }) async {
    try {
      final model = await _remote.createMateri(
        guruMapelId: guruMapelId,
        judul: judul,
        deskripsi: deskripsi,
        fileMateri: fileMateri,
        linkVideo: linkVideo,
        status: status,
      );
      return success(model.toEntity());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    }
  }

  @override
  Future<Result<MateriEntity>> updateMateri({
    required int id,
    int? guruMapelId,
    String? judul,
    String? deskripsi,
    String? fileMateri,
    String? linkVideo,
    int? status,
  }) async {
    try {
      final model = await _remote.updateMateri(
        id: id,
        guruMapelId: guruMapelId,
        judul: judul,
        deskripsi: deskripsi,
        fileMateri: fileMateri,
        linkVideo: linkVideo,
        status: status,
      );
      return success(model.toEntity());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    }
  }

  @override
  Future<Result<bool>> deleteMateri(int id) async {
    try {
      return success(await _remote.deleteMateri(id));
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    }
  }

  @override
  Future<Result<List<LogAksesMateriEntity>>> getLogAksesByMateri(
    int materiId,
  ) async {
    try {
      final models = await _remote.getLogAksesByMateri(materiId);
      return success(models.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    }
  }

  @override
  Future<Result<List<LogAksesMateriEntity>>> getLogAksesBySiswa(
    int siswaId,
  ) async {
    try {
      final models = await _remote.getLogAksesBySiswa(siswaId);
      return success(models.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    }
  }

  @override
  Future<Result<LogAksesMateriEntity>> catatAkses({
    required int materiId,
    required int siswaId,
    required int kelasId,
  }) async {
    try {
      final model = await _remote.catatAkses(
        materiId: materiId,
        siswaId: siswaId,
        kelasId: kelasId,
      );
      return success(model.toEntity());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    }
  }

  @override
  Future<Result<LogAksesMateriEntity>> updateDurasi({
    required int logId,
    required int durasiDetik,
  }) async {
    try {
      final model = await _remote.updateDurasi(
        logId: logId,
        durasiDetik: durasiDetik,
      );
      return success(model.toEntity());
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
