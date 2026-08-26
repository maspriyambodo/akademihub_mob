import 'dart:io';

import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/rapor_detail_entity.dart';
import '../../domain/entities/rapor_entity.dart';
import '../../domain/repositories/rapor_repository.dart';
import '../datasources/rapor_remote_datasource.dart';

class RaporRepositoryImpl implements RaporRepository {
  final RaporRemoteDataSource _remote;

  const RaporRepositoryImpl(this._remote);

  @override
  Future<Result<List<RaporEntity>>> getRaporList({String? search}) async {
    try {
      final models = await _remote.getRaporList(search: search);
      return success(models.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    } on AppException catch (e) {
      return fail(_map(e));
    }
  }

  @override
  Future<Result<List<RaporEntity>>> getRaporBySiswa(int siswaId) async {
    try {
      final models = await _remote.getRaporBySiswa(siswaId);
      return success(models.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    } on AppException catch (e) {
      return fail(_map(e));
    }
  }

  @override
  Future<Result<RaporDetailEntity>> getRaporDetail(int raporId) async {
    try {
      final model = await _remote.getRaporDetail(raporId);
      return success(model.toEntity());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    } on AppException catch (e) {
      return fail(_map(e));
    }
  }

  @override
  Future<Result<RaporEntity>> createRapor({
    required int siswaId,
    required int semester,
    String? catatanWali,
    int? sakit,
    int? izin,
    int? tanpaKeterangan,
    List<Map<String, dynamic>>? details,
  }) async {
    try {
      final model = await _remote.createRapor(
        siswaId: siswaId,
        semester: semester,
        catatanWali: catatanWali,
        sakit: sakit,
        izin: izin,
        tanpaKeterangan: tanpaKeterangan,
        details: details,
      );
      return success(model.toEntity());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    } on AppException catch (e) {
      return fail(_map(e));
    }
  }

  @override
  Future<Result<RaporEntity>> updateRapor({
    required int id,
    int? siswaId,
    int? semester,
    String? catatanWali,
    int? sakit,
    int? izin,
    int? tanpaKeterangan,
  }) async {
    try {
      final model = await _remote.updateRapor(
        id: id,
        siswaId: siswaId,
        semester: semester,
        catatanWali: catatanWali,
        sakit: sakit,
        izin: izin,
        tanpaKeterangan: tanpaKeterangan,
      );
      return success(model.toEntity());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    } on AppException catch (e) {
      return fail(_map(e));
    }
  }

  @override
  Future<Result<bool>> deleteRapor(int id) async {
    try {
      return success(await _remote.deleteRapor(id));
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    } on AppException catch (e) {
      return fail(_map(e));
    }
  }

  @override
  Future<Result<String>> exportRaporSiswa(int siswaId) async {
    try {
      final path = await _remote.exportRaporSiswa(siswaId);
      return success(path);
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    } on AppException catch (e) {
      return fail(_map(e));
    } on FileSystemException catch (e) {
      return fail(ServerFailure('Gagal menyimpan berkas rapor: ${e.message}'));
    }
  }

  Failure _map(AppException e) {
    if (e is NetworkException) return NetworkFailure(e.message);
    if (e is AuthException) return AuthFailure(e.message);
    if (e is ForbiddenException) return ForbiddenFailure(e.message);
    return ServerFailure(e.message);
  }
}
