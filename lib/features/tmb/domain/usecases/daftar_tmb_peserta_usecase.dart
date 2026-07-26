import '../../../../core/error/result.dart';
import '../entities/tmb_peserta_entity.dart';
import '../repositories/tmb_repository.dart';

class DaftarTmbPesertaUseCase {
  final TmbRepository _repository;
  const DaftarTmbPesertaUseCase(this._repository);

  Future<Result<TmbPesertaEntity>> call({
    required int tesId,
    required int siswaId,
  }) => _repository.daftarPeserta(tesId: tesId, siswaId: siswaId);
}
