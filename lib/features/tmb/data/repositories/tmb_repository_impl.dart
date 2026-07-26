import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/tmb_hasil_entity.dart';
import '../../domain/entities/tmb_jawaban_entity.dart';
import '../../domain/entities/tmb_pertanyaan_entity.dart';
import '../../domain/entities/tmb_peserta_entity.dart';
import '../../domain/entities/tmb_tes_entity.dart';
import '../../domain/repositories/tmb_repository.dart';
import '../datasources/tmb_remote_datasource.dart';

class TmbRepositoryImpl implements TmbRepository {
  final TmbRemoteDataSource _remote;

  const TmbRepositoryImpl(this._remote);

  @override
  Future<Result<List<TmbTesEntity>>> getTesList() async {
    try {
      final models = await _remote.getTesList();
      return success(models.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      return fail(_mapDio(e));
    } on AppException catch (e) {
      return fail(_map(e));
    }
  }

  @override
  Future<Result<List<TmbTesEntity>>> getTesByKelas(int kelasId) async {
    try {
      final models = await _remote.getTesByKelas(kelasId);
      return success(models.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      return fail(_mapDio(e));
    } on AppException catch (e) {
      return fail(_map(e));
    }
  }

  @override
  Future<Result<List<TmbPertanyaanEntity>>> getPertanyaan(
    int tesId, {
    required bool viaTesDetail,
  }) async {
    try {
      final models = viaTesDetail
          ? await _remote.getPertanyaanViaTesDetail(tesId)
          : await _remote.getPertanyaanByTes(tesId);
      return success(models.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      return fail(_mapDio(e));
    } on AppException catch (e) {
      return fail(_map(e));
    }
  }

  @override
  Future<Result<List<TmbPesertaEntity>>> getPesertaBySiswa(int siswaId) async {
    try {
      final models = await _remote.getPesertaBySiswa(siswaId);
      return success(models.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      return fail(_mapDio(e));
    } on AppException catch (e) {
      return fail(_map(e));
    }
  }

  @override
  Future<Result<List<TmbPesertaEntity>>> getPesertaByTes(int tesId) async {
    try {
      final models = await _remote.getPesertaByTes(tesId);
      return success(models.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      return fail(_mapDio(e));
    } on AppException catch (e) {
      return fail(_map(e));
    }
  }

  @override
  Future<Result<TmbPesertaEntity>> daftarPeserta({
    required int tesId,
    required int siswaId,
  }) async {
    try {
      final model = await _remote.daftarPeserta(tesId: tesId, siswaId: siswaId);
      return success(model.toEntity());
    } on DioException catch (e) {
      return fail(_mapDio(e));
    } on AppException catch (e) {
      return fail(_map(e));
    }
  }

  @override
  Future<Result<TmbPesertaEntity>> mulaiTes(int pesertaId) async {
    try {
      final model = await _remote.mulaiTes(pesertaId);
      return success(model.toEntity());
    } on DioException catch (e) {
      return fail(_mapDio(e));
    } on AppException catch (e) {
      return fail(_map(e));
    }
  }

  @override
  Future<Result<TmbPesertaEntity>> selesaikanTes(int pesertaId) async {
    try {
      final model = await _remote.selesaikanTes(pesertaId);
      return success(model.toEntity());
    } on DioException catch (e) {
      return fail(_mapDio(e));
    } on AppException catch (e) {
      return fail(_map(e));
    }
  }

  @override
  Future<Result<TmbJawabanEntity>> kirimJawaban({
    required int pesertaId,
    required int pertanyaanId,
    int? opsiId,
    String? jawabanTeks,
  }) async {
    try {
      final model = await _remote.kirimJawaban(
        pesertaId: pesertaId,
        pertanyaanId: pertanyaanId,
        opsiId: opsiId,
        jawabanTeks: jawabanTeks,
      );
      return success(model.toEntity());
    } on DioException catch (e) {
      return fail(_mapDio(e));
    } on AppException catch (e) {
      return fail(_map(e));
    }
  }

  @override
  Future<Result<List<TmbJawabanEntity>>> getJawabanByPeserta(
    int pesertaId,
  ) async {
    try {
      final models = await _remote.getJawabanByPeserta(pesertaId);
      return success(models.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      return fail(_mapDio(e));
    } on AppException catch (e) {
      return fail(_map(e));
    }
  }

  @override
  Future<Result<List<TmbHasilEntity>>> getHasilByPeserta(int pesertaId) async {
    try {
      final models = await _remote.getHasilByPeserta(pesertaId);
      return success(models.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      return fail(_mapDio(e));
    } on AppException catch (e) {
      return fail(_map(e));
    }
  }

  /// 403 tidak dipetakan khusus oleh `mapDioException` (jatuh ke
  /// ServerException), padahal itu kasus umum di modul ini karena setiap
  /// endpoint dilindungi PermissionMiddleware.
  Failure _mapDio(DioException e) {
    if (e.response?.statusCode == 403) {
      final data = e.response?.data;
      final pesan = data is Map ? data['message']?.toString() : null;
      return TmbAccessFailure(
        pesan == null || pesan.trim().isEmpty
            ? 'Anda tidak memiliki izin mengakses tes minat bakat'
            : pesan,
      );
    }
    return _map(mapDioException(e));
  }

  Failure _map(AppException e) {
    if (e is NetworkException) return NetworkFailure(e.message);
    if (e is AuthException) return AuthFailure(e.message);
    if (e is NotFoundException) return NotFoundFailure(e.message);
    if (e is ValidationException) {
      return ValidationFailure(e.message, errors: e.errors);
    }
    return ServerFailure(e.message);
  }
}
