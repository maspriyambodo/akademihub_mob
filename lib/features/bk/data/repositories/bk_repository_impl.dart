import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/bk_hasil_entity.dart';
import '../../domain/entities/bk_jenis_entity.dart';
import '../../domain/entities/bk_kasus_entity.dart';
import '../../domain/entities/bk_sesi_entity.dart';
import '../../domain/entities/bk_siswa_ringkas_entity.dart';
import '../../domain/entities/bk_tindakan_entity.dart';
import '../../domain/repositories/bk_repository.dart';
import '../datasources/bk_remote_datasource.dart';

class BkRepositoryImpl implements BkRepository {
  final BkRemoteDataSource _remote;

  const BkRepositoryImpl(this._remote);

  @override
  Future<Result<List<BkKasusEntity>>> getKasusList() async {
    try {
      final models = await _remote.getKasusList();
      return success(models.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    }
  }

  @override
  Future<Result<List<BkKasusEntity>>> getKasusBySiswa(int siswaId) async {
    try {
      final models = await _remote.getKasusBySiswa(siswaId);
      return success(models.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    }
  }

  @override
  Future<Result<List<BkSesiEntity>>> getSesiByKasus(int kasusId) async {
    try {
      final models = await _remote.getSesiByKasus(kasusId);
      return success(models.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    }
  }

  @override
  Future<Result<List<BkHasilEntity>>> getHasilByKasus(int kasusId) async {
    try {
      final models = await _remote.getHasilByKasus(kasusId);
      return success(models.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    }
  }

  @override
  Future<Result<List<BkTindakanEntity>>> getTindakanByKasus(
    int kasusId,
  ) async {
    try {
      final models = await _remote.getTindakanByKasus(kasusId);
      return success(models.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    }
  }

  @override
  Future<Result<List<BkJenisEntity>>> getJenisList() async {
    try {
      final models = await _remote.getJenisList();
      return success(models.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    }
  }

  @override
  Future<Result<List<BkSiswaRingkasEntity>>> searchSiswa(String query) async {
    try {
      final models = await _remote.searchSiswa(query);
      return success(models.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    }
  }

  @override
  Future<Result<BkKasusEntity>> createKasus({
    required int siswaId,
    required int guruId,
    required int jenisId,
    required String tanggal,
    required String keterangan,
  }) async {
    try {
      final model = await _remote.createKasus(
        siswaId: siswaId,
        guruId: guruId,
        jenisId: jenisId,
        tanggal: tanggal,
        keterangan: keterangan,
      );
      return success(model.toEntity());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    }
  }

  @override
  Future<Result<BkSesiEntity>> createSesi({
    required int kasusId,
    required String tanggal,
    required int metode,
    required String catatan,
  }) async {
    try {
      final model = await _remote.createSesi(
        kasusId: kasusId,
        tanggal: tanggal,
        metode: metode,
        catatan: catatan,
      );
      return success(model.toEntity());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    }
  }

  @override
  Future<Result<BkHasilEntity>> createHasil({
    required int kasusId,
    required String hasil,
    required String rekomendasi,
  }) async {
    try {
      final model = await _remote.createHasil(
        kasusId: kasusId,
        hasil: hasil,
        rekomendasi: rekomendasi,
      );
      return success(model.toEntity());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    }
  }

  @override
  Future<Result<BkTindakanEntity>> createTindakan({
    required int kasusId,
    required String deskripsi,
  }) async {
    try {
      final model = await _remote.createTindakan(
        kasusId: kasusId,
        deskripsi: deskripsi,
      );
      return success(model.toEntity());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    }
  }

  Failure _map(AppException e) {
    if (e is NetworkException) return NetworkFailure(e.message);
    if (e is AuthException) return AuthFailure(e.message);
    if (e is ValidationException) {
      return ValidationFailure(e.message, errors: e.errors);
    }
    if (e is NotFoundException) return NotFoundFailure(e.message);
    return ServerFailure(e.message);
  }
}
