import '../../../../core/error/result.dart';
import '../entities/tmb_peserta_entity.dart';
import '../repositories/tmb_repository.dart';

class MulaiTmbUseCase {
  final TmbRepository _repository;
  const MulaiTmbUseCase(this._repository);

  Future<Result<TmbPesertaEntity>> call(int pesertaId) =>
      _repository.mulaiTes(pesertaId);
}
