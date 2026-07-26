import '../../../../core/error/result.dart';
import '../entities/pembayaran_online_entity.dart';
import '../entities/pembayaran_spp_entity.dart';
import '../repositories/keuangan_repository.dart';

/// Aksi tulis — hanya boleh dipanggil bila user punya permission
/// `pembayaran-spp.bayar` (route memakai `PermissionMiddleware`).
class BayarSppUseCase {
  final KeuanganRepository _repository;
  const BayarSppUseCase(this._repository);

  Future<Result<PembayaranSppEntity>> call({
    required int siswaId,
    required int tarifSppId,
    required int bulan,
    required int tahun,
    required double jumlahBayar,
    String? tanggalBayar,
    int? status,
    int? metodePembayaran,
    String? keterangan,
  }) => _repository.bayarSpp(
    siswaId: siswaId,
    tarifSppId: tarifSppId,
    bulan: bulan,
    tahun: tahun,
    jumlahBayar: jumlahBayar,
    tanggalBayar: tanggalBayar,
    status: status,
    metodePembayaran: metodePembayaran,
    keterangan: keterangan,
  );
}

class BayarMultipleSppUseCase {
  final KeuanganRepository _repository;
  const BayarMultipleSppUseCase(this._repository);

  Future<Result<List<PembayaranSppEntity>>> call({
    required int siswaId,
    required int tarifSppId,
    required List<int> bulan,
    required int tahun,
    double? jumlahBayarPerBulan,
    String? tanggalBayar,
    String? metodePembayaran,
    String? keterangan,
  }) => _repository.bayarMultiple(
    siswaId: siswaId,
    tarifSppId: tarifSppId,
    bulan: bulan,
    tahun: tahun,
    jumlahBayarPerBulan: jumlahBayarPerBulan,
    tanggalBayar: tanggalBayar,
    metodePembayaran: metodePembayaran,
    keterangan: keterangan,
  );
}

class BayarOnlineSppUseCase {
  final KeuanganRepository _repository;
  const BayarOnlineSppUseCase(this._repository);

  Future<Result<PembayaranOnlineEntity>> call({
    required int siswaId,
    required int tarifSppId,
    required int bulan,
    required int tahun,
  }) => _repository.bayarOnline(
    siswaId: siswaId,
    tarifSppId: tarifSppId,
    bulan: bulan,
    tahun: tahun,
  );
}
