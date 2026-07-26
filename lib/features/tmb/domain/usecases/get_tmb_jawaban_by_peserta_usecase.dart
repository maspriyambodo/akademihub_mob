import '../../../../core/error/result.dart';
import '../entities/tmb_jawaban_entity.dart';
import '../repositories/tmb_repository.dart';

class GetTmbJawabanByPesertaUseCase {
  final TmbRepository _repository;
  const GetTmbJawabanByPesertaUseCase(this._repository);

  Future<Result<List<TmbJawabanEntity>>> call(int pesertaId) =>
      _repository.getJawabanByPeserta(pesertaId);
}
