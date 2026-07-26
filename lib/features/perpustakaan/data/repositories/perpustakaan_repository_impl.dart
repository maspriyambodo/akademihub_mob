import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/buku_entity.dart';
import '../../domain/entities/buku_riwayat_entity.dart';
import '../../domain/entities/peminjaman_buku_entity.dart';
import '../../domain/repositories/perpustakaan_repository.dart';
import '../datasources/perpustakaan_remote_datasource.dart';

class PerpustakaanRepositoryImpl implements PerpustakaanRepository {
  final PerpustakaanRemoteDataSource _remote;

  const PerpustakaanRepositoryImpl(this._remote);

  @override
  Future<Result<List<BukuEntity>>> getBukuList({
    int perPage = 200,
    String? search,
  }) async {
    try {
      final models = await _remote.getBukuList(
        perPage: perPage,
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
  Future<Result<List<BukuEntity>>> getBukuAvailable() async {
    try {
      final models = await _remote.getBukuAvailable();
      return success(models.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    } on AppException catch (e) {
      return fail(_map(e));
    }
  }

  @override
  Future<Result<BukuEntity>> getBukuDetail(int bukuId) async {
    try {
      final model = await _remote.getBukuDetail(bukuId);
      return success(model.toEntity());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    } on AppException catch (e) {
      return fail(_map(e));
    }
  }

  @override
  Future<Result<BukuRiwayatEntity>> getRiwayatBuku(int bukuId) async {
    try {
      final model = await _remote.getRiwayatBuku(bukuId);
      return success(model.toEntity());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    } on AppException catch (e) {
      return fail(_map(e));
    }
  }

  @override
  Future<Result<List<PeminjamanBukuEntity>>> getPeminjamanList({
    int perPage = 100,
  }) async {
    try {
      final models = await _remote.getPeminjamanList(perPage: perPage);
      return success(models.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    } on AppException catch (e) {
      return fail(_map(e));
    }
  }

  @override
  Future<Result<List<PeminjamanBukuEntity>>> getPeminjamanBySiswa(
    int siswaId,
  ) async {
    try {
      final models = await _remote.getPeminjamanBySiswa(siswaId);
      return success(models.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    } on AppException catch (e) {
      return fail(_map(e));
    }
  }

  @override
  Future<Result<List<PeminjamanBukuEntity>>> getPeminjamanOverdue() async {
    try {
      final models = await _remote.getPeminjamanOverdue();
      return success(models.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    } on AppException catch (e) {
      return fail(_map(e));
    }
  }

  @override
  Future<Result<PeminjamanBukuEntity>> createPeminjaman({
    required int siswaId,
    required int bukuId,
    String? tanggalPinjam,
    required String tanggalJatuhTempo,
  }) async {
    try {
      final model = await _remote.createPeminjaman(
        siswaId: siswaId,
        bukuId: bukuId,
        tanggalPinjam: tanggalPinjam,
        tanggalJatuhTempo: tanggalJatuhTempo,
      );
      return success(model.toEntity());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    } on AppException catch (e) {
      return fail(_map(e));
    }
  }

  @override
  Future<Result<PeminjamanBukuEntity>> prosesPengembalian(
    int peminjamanId,
  ) async {
    try {
      final model = await _remote.prosesPengembalian(peminjamanId);
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
    if (e is NotFoundException) return NotFoundFailure(e.message);
    if (e is ValidationException) {
      return ValidationFailure(e.message, errors: e.errors);
    }
    return ServerFailure(e.message);
  }
}
