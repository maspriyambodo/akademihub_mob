import 'dart:io';

import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/kelas_option_entity.dart';
import '../../domain/entities/ranking_entity.dart';
import '../../domain/entities/ujian_entity.dart';
import '../../domain/entities/ujian_nilai_entity.dart';
import '../../domain/repositories/ujian_repository.dart';
import '../datasources/ujian_remote_datasource.dart';

class UjianRepositoryImpl implements UjianRepository {
  final UjianRemoteDataSource _remote;

  const UjianRepositoryImpl(this._remote);

  @override
  Future<Result<List<UjianEntity>>> getUjianByKelas(int kelasId) async {
    try {
      final models = await _remote.getUjianByKelas(kelasId);
      return success(models.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    } on AppException catch (e) {
      return fail(_map(e));
    }
  }

  @override
  Future<Result<UjianNilaiDetailEntity>> getNilaiUjian(int ujianId) async {
    try {
      final model = await _remote.getNilaiUjian(ujianId);
      return success(model.toEntity());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    } on AppException catch (e) {
      return fail(_map(e));
    }
  }

  @override
  Future<Result<List<RankingEntity>>> getRankingByKelas(int kelasId) async {
    try {
      final models = await _remote.getRankingByKelas(kelasId);
      return success(models.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    } on AppException catch (e) {
      return fail(_map(e));
    }
  }

  @override
  Future<Result<List<RankingEntity>>> generateRanking({
    required int kelasId,
    required int semesterId,
    required int tahunAjaranId,
  }) async {
    try {
      final models = await _remote.generateRanking(
        kelasId: kelasId,
        semesterId: semesterId,
        tahunAjaranId: tahunAjaranId,
      );
      return success(models.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    } on AppException catch (e) {
      return fail(_map(e));
    }
  }

  @override
  Future<Result<String>> exportRanking({
    required int kelasId,
    required int semesterId,
    required int tahunAjaranId,
  }) async {
    try {
      final path = await _remote.exportRanking(
        kelasId: kelasId,
        semesterId: semesterId,
        tahunAjaranId: tahunAjaranId,
      );
      return success(path);
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    } on AppException catch (e) {
      return fail(_map(e));
    } on FileSystemException catch (e) {
      return fail(ServerFailure('Gagal menyimpan berkas ranking: ${e.message}'));
    }
  }

  @override
  Future<Result<List<KelasOptionEntity>>> getKelasOptions({
    int? waliGuruId,
  }) async {
    try {
      final models = await _remote.getKelasOptions(waliGuruId: waliGuruId);
      return success(models.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    } on AppException catch (e) {
      return fail(_map(e));
    }
  }

  Failure _map(AppException e) {
    if (e is NetworkException) return NetworkFailure(e.message);
    if (e is AuthException) return AuthFailure(e.message);
    return ServerFailure(e.message);
  }
}
