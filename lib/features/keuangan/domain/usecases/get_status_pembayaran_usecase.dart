import '../../../../core/error/result.dart';
import '../entities/status_pembayaran_entity.dart';
import '../entities/tunggakan_entity.dart';
import '../repositories/keuangan_repository.dart';

class GetStatusPembayaranUseCase {
  final KeuanganRepository _repository;
  const GetStatusPembayaranUseCase(this._repository);

  Future<Result<StatusPembayaranEntity>> call(
    int siswaId, {
    String? tahunAjaran,
  }) => _repository.getStatusPembayaran(siswaId, tahunAjaran: tahunAjaran);
}

class GetTunggakanUseCase {
  final KeuanganRepository _repository;
  const GetTunggakanUseCase(this._repository);

  Future<Result<List<TunggakanEntity>>> call({
    required int siswaId,
    required int tarifSppId,
    required int tahun,
  }) => _repository.getTunggakan(
    siswaId: siswaId,
    tarifSppId: tarifSppId,
    tahun: tahun,
  );
}

class HitungDendaUseCase {
  final KeuanganRepository _repository;
  const HitungDendaUseCase(this._repository);

  Future<Result<DendaEntity>> call({
    required int tarifSppId,
    required int bulan,
    required int tahun,
    String? tanggalBayar,
  }) => _repository.hitungDenda(
    tarifSppId: tarifSppId,
    bulan: bulan,
    tahun: tahun,
    tanggalBayar: tanggalBayar,
  );
}
