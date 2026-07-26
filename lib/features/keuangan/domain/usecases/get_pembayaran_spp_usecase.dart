import '../../../../core/error/result.dart';
import '../entities/pembayaran_spp_entity.dart';
import '../repositories/keuangan_repository.dart';

class GetPembayaranListUseCase {
  final KeuanganRepository _repository;
  const GetPembayaranListUseCase(this._repository);

  Future<Result<List<PembayaranSppEntity>>> call({
    String? search,
    int? tahun,
    int? bulan,
    String? status,
  }) => _repository.getPembayaranList(
    search: search,
    tahun: tahun,
    bulan: bulan,
    status: status,
  );
}

class GetPembayaranBySiswaUseCase {
  final KeuanganRepository _repository;
  const GetPembayaranBySiswaUseCase(this._repository);

  Future<Result<List<PembayaranSppEntity>>> call(int siswaId) =>
      _repository.getPembayaranBySiswa(siswaId);
}

class GetPembayaranDetailUseCase {
  final KeuanganRepository _repository;
  const GetPembayaranDetailUseCase(this._repository);

  Future<Result<PembayaranSppEntity>> call(int id) =>
      _repository.getPembayaranDetail(id);
}
