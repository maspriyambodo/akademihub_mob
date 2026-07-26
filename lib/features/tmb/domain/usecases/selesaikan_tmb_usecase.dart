import '../../../../core/error/result.dart';
import '../entities/tmb_peserta_entity.dart';
import '../repositories/tmb_repository.dart';

class SelesaikanTmbUseCase {
  final TmbRepository _repository;
  const SelesaikanTmbUseCase(this._repository);

  Future<Result<TmbPesertaEntity>> call(int pesertaId) =>
      _repository.selesaikanTes(pesertaId);
}
