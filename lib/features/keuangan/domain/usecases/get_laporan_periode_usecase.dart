import '../../../../core/error/result.dart';
import '../entities/laporan_periode_entity.dart';
import '../repositories/keuangan_repository.dart';

class GetLaporanPeriodeUseCase {
  final KeuanganRepository _repository;
  const GetLaporanPeriodeUseCase(this._repository);

  Future<Result<LaporanPeriodeEntity>> call({
    int? tahun,
    int? bulanDari,
    int? bulanSampai,
    int? kelasId,
    int? tahunAjaranId,
  }) => _repository.getLaporanPeriode(
    tahun: tahun,
    bulanDari: bulanDari,
    bulanSampai: bulanSampai,
    kelasId: kelasId,
    tahunAjaranId: tahunAjaranId,
  );
}
