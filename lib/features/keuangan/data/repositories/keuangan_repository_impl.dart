import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/laporan_periode_entity.dart';
import '../../domain/entities/pembayaran_online_entity.dart';
import '../../domain/entities/pembayaran_spp_entity.dart';
import '../../domain/entities/status_pembayaran_entity.dart';
import '../../domain/entities/tarif_spp_entity.dart';
import '../../domain/entities/tunggakan_entity.dart';
import '../../domain/repositories/keuangan_repository.dart';
import '../datasources/keuangan_remote_datasource.dart';

class KeuanganRepositoryImpl implements KeuanganRepository {
  final KeuanganRemoteDataSource _remote;

  const KeuanganRepositoryImpl(this._remote);

  @override
  Future<Result<List<PembayaranSppEntity>>> getPembayaranList({
    String? search,
    int? tahun,
    int? bulan,
    String? status,
  }) async {
    try {
      final models = await _remote.getPembayaranList(
        search: search,
        tahun: tahun,
        bulan: bulan,
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
  Future<Result<PembayaranSppEntity>> getPembayaranDetail(int id) async {
    try {
      final model = await _remote.getPembayaranDetail(id);
      return success(model.toEntity());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    } on AppException catch (e) {
      return fail(_map(e));
    }
  }

  @override
  Future<Result<List<PembayaranSppEntity>>> getPembayaranBySiswa(
    int siswaId,
  ) async {
    try {
      final models = await _remote.getPembayaranBySiswa(siswaId);
      return success(models.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    } on AppException catch (e) {
      return fail(_map(e));
    }
  }

  @override
  Future<Result<StatusPembayaranEntity>> getStatusPembayaran(
    int siswaId, {
    String? tahunAjaran,
  }) async {
    try {
      final model = await _remote.getStatusPembayaran(
        siswaId,
        tahunAjaran: tahunAjaran,
      );
      return success(model.toEntity());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    } on AppException catch (e) {
      return fail(_map(e));
    }
  }

  @override
  Future<Result<List<TunggakanEntity>>> getTunggakan({
    required int siswaId,
    required int tarifSppId,
    required int tahun,
  }) async {
    try {
      final models = await _remote.getTunggakan(
        siswaId: siswaId,
        tarifSppId: tarifSppId,
        tahun: tahun,
      );
      return success(models.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    } on AppException catch (e) {
      return fail(_map(e));
    }
  }

  @override
  Future<Result<DendaEntity>> hitungDenda({
    required int tarifSppId,
    required int bulan,
    required int tahun,
    String? tanggalBayar,
  }) async {
    try {
      final model = await _remote.hitungDenda(
        tarifSppId: tarifSppId,
        bulan: bulan,
        tahun: tahun,
        tanggalBayar: tanggalBayar,
      );
      return success(model.toEntity());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    } on AppException catch (e) {
      return fail(_map(e));
    }
  }

  @override
  Future<Result<LaporanPeriodeEntity>> getLaporanPeriode({
    int? tahun,
    int? bulanDari,
    int? bulanSampai,
    int? kelasId,
    int? tahunAjaranId,
  }) async {
    try {
      final model = await _remote.getLaporanPeriode(
        tahun: tahun,
        bulanDari: bulanDari,
        bulanSampai: bulanSampai,
        kelasId: kelasId,
        tahunAjaranId: tahunAjaranId,
      );
      return success(model.toEntity());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    } on AppException catch (e) {
      return fail(_map(e));
    }
  }

  @override
  Future<Result<List<TarifSppEntity>>> getTarifList({String? search}) async {
    try {
      final models = await _remote.getTarifList(search: search);
      return success(models.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    } on AppException catch (e) {
      return fail(_map(e));
    }
  }

  @override
  Future<Result<TarifSppEntity>> getTarifDetail(int id) async {
    try {
      final model = await _remote.getTarifDetail(id);
      return success(model.toEntity());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    } on AppException catch (e) {
      return fail(_map(e));
    }
  }

  @override
  Future<Result<TarifSppEntity>> getTarifByKelas(
    int kelasId, {
    int? tahunAjaranId,
  }) async {
    try {
      final model = await _remote.getTarifByKelas(
        kelasId,
        tahunAjaranId: tahunAjaranId,
      );
      return success(model.toEntity());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    } on AppException catch (e) {
      return fail(_map(e));
    }
  }

  @override
  Future<Result<PembayaranSppEntity>> bayarSpp({
    required int siswaId,
    required int tarifSppId,
    required int bulan,
    required int tahun,
    required double jumlahBayar,
    String? tanggalBayar,
    int? status,
    int? metodePembayaran,
    String? keterangan,
  }) async {
    try {
      final model = await _remote.bayarSpp(<String, dynamic>{
        'mst_siswa_id': siswaId,
        'mst_tarif_spp_id': tarifSppId,
        'bulan': bulan,
        'tahun': tahun,
        'jumlah_bayar': jumlahBayar,
        'tanggal_bayar': ?tanggalBayar,
        // `CreatePembayaranSppRequest` memvalidasi status & metode sebagai
        // INTEGER 1..4 (kode `sys_references`), bukan string.
        'status': status ?? 1,
        'metode_pembayaran': metodePembayaran ?? 1,
        if (keterangan != null && keterangan.isNotEmpty)
          'keterangan': keterangan,
      });
      return success(model.toEntity());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    } on AppException catch (e) {
      return fail(_map(e));
    }
  }

  @override
  Future<Result<List<PembayaranSppEntity>>> bayarMultiple({
    required int siswaId,
    required int tarifSppId,
    required List<int> bulan,
    required int tahun,
    double? jumlahBayarPerBulan,
    String? tanggalBayar,
    String? metodePembayaran,
    String? keterangan,
  }) async {
    try {
      final models = await _remote.bayarMultiple(<String, dynamic>{
        'mst_siswa_id': siswaId,
        'mst_tarif_spp_id': tarifSppId,
        'bulan': bulan,
        'tahun': tahun,
        'jumlah_bayar_per_bulan': ?jumlahBayarPerBulan,
        'tanggal_bayar': ?tanggalBayar,
        'metode_pembayaran': ?metodePembayaran,
        if (keterangan != null && keterangan.isNotEmpty)
          'keterangan': keterangan,
      });
      return success(models.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    } on AppException catch (e) {
      return fail(_map(e));
    }
  }

  @override
  Future<Result<PembayaranOnlineEntity>> bayarOnline({
    required int siswaId,
    required int tarifSppId,
    required int bulan,
    required int tahun,
  }) async {
    try {
      final model = await _remote.bayarOnline(<String, dynamic>{
        'mst_siswa_id': siswaId,
        'mst_tarif_spp_id': tarifSppId,
        'bulan': bulan,
        'tahun': tahun,
      });
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
    if (e is ValidationException) return ValidationFailure(e.message);
    return ServerFailure(e.message);
  }
}
