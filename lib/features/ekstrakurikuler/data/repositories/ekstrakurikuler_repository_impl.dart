import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/ekstrakurikuler_entity.dart';
import '../../domain/entities/ekstrakurikuler_statistik_entity.dart';
import '../../domain/entities/pendaftaran_ekskul_entity.dart';
import '../../domain/repositories/ekstrakurikuler_repository.dart';
import '../datasources/ekstrakurikuler_remote_datasource.dart';

class EkstrakurikulerRepositoryImpl implements EkstrakurikulerRepository {
  final EkstrakurikulerRemoteDataSource _remote;

  const EkstrakurikulerRepositoryImpl(this._remote);

  @override
  Future<Result<List<EkstrakurikulerEntity>>> getEkstrakurikulerAktif() async {
    try {
      final models = await _remote.getEkstrakurikulerAktif();
      return success(models.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    } on AppException catch (e) {
      return fail(_map(e));
    }
  }

  @override
  Future<Result<List<EkstrakurikulerEntity>>> getEkstrakurikulerList({
    String? status,
    String? search,
  }) async {
    try {
      final models = await _remote.getEkstrakurikulerList(
        status: status,
        search: search,
      );
      return success(models.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    } on AppException catch (e) {
      return fail(_map(e));
    }
  }

  @override
  Future<Result<EkstrakurikulerEntity>> getEkstrakurikulerDetail(
    int id,
  ) async {
    try {
      final model = await _remote.getEkstrakurikulerDetail(id);
      return success(model.toEntity());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    } on AppException catch (e) {
      return fail(_map(e));
    }
  }

  @override
  Future<Result<EkstrakurikulerStatistikEntity>> getStatistik(int id) async {
    try {
      final model = await _remote.getStatistik(id);
      return success(model.toEntity());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    } on AppException catch (e) {
      return fail(_map(e));
    }
  }

  @override
  Future<Result<List<EkstrakurikulerEntity>>> getByPembina(
    int pembinaGuruId,
  ) async {
    try {
      final models = await _remote.getByPembina(pembinaGuruId);
      return success(models.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    } on AppException catch (e) {
      return fail(_map(e));
    }
  }

  @override
  Future<Result<List<PendaftaranEkskulEntity>>> getPesertaByEkstrakurikuler(
    int ekstrakurikulerId,
  ) async {
    try {
      final models = await _remote.getPesertaByEkstrakurikuler(
        ekstrakurikulerId,
      );
      return success(models.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    } on AppException catch (e) {
      return fail(_map(e));
    }
  }

  @override
  Future<Result<List<PendaftaranEkskulEntity>>> getPendaftaranBySiswa(
    int siswaId,
  ) async {
    try {
      final models = await _remote.getPendaftaranBySiswa(siswaId);
      return success(models.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    } on AppException catch (e) {
      return fail(_map(e));
    }
  }

  @override
  Future<Result<List<PendaftaranEkskulEntity>>> getRiwayatBySiswa(
    int siswaId,
  ) async {
    try {
      final models = await _remote.getRiwayatBySiswa(siswaId);
      return success(models.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    } on AppException catch (e) {
      return fail(_map(e));
    }
  }

  @override
  Future<Result<List<PendaftaranEkskulEntity>>> getPendaftaranList({
    int? siswaId,
    int? ekstrakurikulerId,
    String? status,
  }) async {
    try {
      final models = await _remote.getPendaftaranList(
        siswaId: siswaId,
        ekstrakurikulerId: ekstrakurikulerId,
        status: status,
      );
      return success(models.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    } on AppException catch (e) {
      return fail(_map(e));
    }
  }

  @override
  Future<Result<PendaftaranEkskulEntity>> daftarEkstrakurikuler({
    required int ekstrakurikulerId,
    required int siswaId,
  }) async {
    try {
      final model = await _remote.daftar(
        ekstrakurikulerId: ekstrakurikulerId,
        siswaId: siswaId,
      );
      return success(model.toEntity());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    } on AppException catch (e) {
      return fail(_map(e));
    }
  }

  @override
  Future<Result<bool>> checkStatusPendaftaran({
    required int siswaId,
    required int ekstrakurikulerId,
  }) async {
    try {
      final terdaftar = await _remote.checkStatus(
        siswaId: siswaId,
        ekstrakurikulerId: ekstrakurikulerId,
      );
      return success(terdaftar);
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    } on AppException catch (e) {
      return fail(_map(e));
    }
  }

  @override
  Future<Result<PendaftaranEkskulEntity>> keluarEkstrakurikuler(
    int pendaftaranId,
  ) async {
    try {
      final model = await _remote.keluar(pendaftaranId);
      return success(model.toEntity());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    } on AppException catch (e) {
      return fail(_map(e));
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
