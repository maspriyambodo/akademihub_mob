import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/ppdb_dokumen_entity.dart';
import '../../domain/entities/ppdb_gelombang_entity.dart';
import '../../domain/entities/ppdb_hasil_seleksi_entity.dart';
import '../../domain/entities/ppdb_pendaftar_entity.dart';
import '../../domain/entities/ppdb_public_entity.dart';
import '../../domain/entities/ppdb_statistik_entity.dart';
import '../../domain/repositories/ppdb_repository.dart';
import '../datasources/ppdb_remote_datasource.dart';

class PpdbRepositoryImpl implements PpdbRepository {
  final PpdbRemoteDataSource _remote;

  const PpdbRepositoryImpl(this._remote);

  @override
  Future<Result<List<PpdbSekolahEntity>>> getSekolahPublik() async {
    try {
      final models = await _remote.getSekolahPublik();
      return success(models.map((model) => model.toEntity()).toList());
    } on DioException catch (e) {
      return fail(_map(e));
    }
  }

  @override
  Future<Result<List<PpdbGelombangEntity>>> getGelombangPublik(
    int sekolahId,
  ) async {
    try {
      final models = await _remote.getGelombangPublik(sekolahId);
      return success(models.map((model) => model.toEntity()).toList());
    } on DioException catch (e) {
      return fail(_map(e));
    }
  }

  @override
  Future<Result<PpdbStatusPublikEntity>> cekStatusPublik(
    String noPendaftaran,
  ) async {
    try {
      return success((await _remote.cekStatusPublik(noPendaftaran)).toEntity());
    } on DioException catch (e) {
      return fail(_map(e));
    } on ServerException catch (e) {
      return fail(ServerFailure(e.message));
    }
  }

  @override
  Future<Result<PpdbPendaftaranPublikEntity>> daftarPublik(
    Map<String, dynamic> data,
  ) async {
    try {
      return success(
        (await _remote.daftarPublik(FormData.fromMap(data))).toEntity(),
      );
    } on DioException catch (e) {
      return fail(_map(e));
    } on ServerException catch (e) {
      return fail(ServerFailure(e.message));
    }
  }

  @override
  Future<Result<List<PpdbGelombangEntity>>> getGelombangList() async {
    try {
      final models = await _remote.getGelombangList();
      return success(models.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      return fail(_map(e));
    }
  }

  @override
  Future<Result<List<PpdbPendaftarEntity>>> getPendaftarList({
    String? search,
    String? statusPendaftaran,
    int? gelombangId,
  }) async {
    try {
      final models = await _remote.getPendaftarList(
        search: search,
        statusPendaftaran: statusPendaftaran,
        gelombangId: gelombangId,
      );
      return success(models.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      return fail(_map(e));
    }
  }

  @override
  Future<Result<PpdbPendaftarEntity>> getPendaftarDetail(int id) async {
    try {
      final model = await _remote.getPendaftarDetail(id);
      return success(model.toEntity());
    } on DioException catch (e) {
      return fail(_map(e));
    } on ServerException catch (e) {
      return fail(ServerFailure(e.message));
    }
  }

  @override
  Future<Result<PpdbStatistikEntity>> getStatistik({
    required int sekolahId,
    int? gelombangId,
  }) async {
    try {
      final model = await _remote.getStatistik(
        sekolahId: sekolahId,
        gelombangId: gelombangId,
      );
      return success(model.toEntity());
    } on DioException catch (e) {
      return fail(_map(e));
    } on ServerException catch (e) {
      return fail(ServerFailure(e.message));
    }
  }

  @override
  Future<Result<List<PpdbDokumenEntity>>> getDokumenByPendaftar(
    int pendaftarId,
  ) async {
    try {
      final models = await _remote.getDokumenByPendaftar(pendaftarId);
      return success(models.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      return fail(_map(e));
    }
  }

  @override
  Future<Result<PpdbNilaiRaporBundle>> getNilaiRapor(int pendaftarId) async {
    try {
      final response = await _remote.getNilaiRapor(pendaftarId);
      return success(
        PpdbNilaiRaporBundle(
          daftar: response.daftar.map((m) => m.toEntity()).toList(),
          statistik: response.statistik.toEntity(),
        ),
      );
    } on DioException catch (e) {
      return fail(_map(e));
    } on ServerException catch (e) {
      return fail(ServerFailure(e.message));
    }
  }

  @override
  Future<Result<List<PpdbHasilSeleksiEntity>>> getHasilSeleksi(
    int gelombangId,
  ) async {
    try {
      final models = await _remote.getHasilSeleksi(gelombangId);
      return success(models.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      return fail(_map(e));
    }
  }

  @override
  Future<Result<PpdbDokumenEntity>> verifikasiDokumen(
    int dokumenId, {
    String? catatan,
  }) async {
    try {
      final model = await _remote.verifikasiDokumen(
        dokumenId,
        catatan: catatan,
      );
      return success(model.toEntity());
    } on DioException catch (e) {
      return fail(_map(e));
    } on ServerException catch (e) {
      return fail(ServerFailure(e.message));
    }
  }

  @override
  Future<Result<PpdbDokumenEntity>> tolakDokumen(
    int dokumenId, {
    required String catatan,
  }) async {
    try {
      final model = await _remote.tolakDokumen(dokumenId, catatan: catatan);
      return success(model.toEntity());
    } on DioException catch (e) {
      return fail(_map(e));
    } on ServerException catch (e) {
      return fail(ServerFailure(e.message));
    }
  }

  @override
  Future<Result<PpdbPendaftarEntity>> ubahStatusPendaftar(
    int pendaftarId, {
    required String aksi,
  }) async {
    try {
      final model = await _remote.ubahStatusPendaftar(pendaftarId, aksi: aksi);
      return success(model.toEntity());
    } on DioException catch (e) {
      return fail(_map(e));
    } on ServerException catch (e) {
      return fail(ServerFailure(e.message));
    }
  }

  /// 403 tidak punya padanan di `mapDioException` (jatuh ke ServerException),
  /// padahal itu kasus paling umum di modul ini: seluruh endpoint PPDB
  /// dilindungi `PermissionMiddleware` dan role siswa/guru/wali tidak punya
  /// satu pun permission `ppdb.*`.
  Failure _map(DioException e) {
    if (e.response?.statusCode == 403) {
      final data = e.response?.data;
      final pesan = data is Map ? data['message']?.toString() : null;
      return PpdbAccessFailure(
        pesan == null || pesan.trim().isEmpty
            ? 'Anda tidak memiliki izin untuk mengakses data PPDB.'
            : pesan,
      );
    }
    return _mapException(mapDioException(e));
  }

  Failure _mapException(AppException e) {
    if (e is NetworkException) return NetworkFailure(e.message);
    if (e is AuthException) return AuthFailure(e.message);
    if (e is NotFoundException) return NotFoundFailure(e.message);
    if (e is ValidationException) {
      return ValidationFailure(e.message, errors: e.errors);
    }
    return ServerFailure(e.message);
  }
}
