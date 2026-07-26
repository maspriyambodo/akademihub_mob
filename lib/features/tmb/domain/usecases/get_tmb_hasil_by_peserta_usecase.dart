import '../../../../core/error/result.dart';
import '../entities/tmb_hasil_entity.dart';
import '../repositories/tmb_repository.dart';

class GetTmbHasilByPesertaUseCase {
  final TmbRepository _repository;
  const GetTmbHasilByPesertaUseCase(this._repository);

  Future<Result<List<TmbHasilEntity>>> call(int pesertaId) =>
      _repository.getHasilByPeserta(pesertaId);
}
