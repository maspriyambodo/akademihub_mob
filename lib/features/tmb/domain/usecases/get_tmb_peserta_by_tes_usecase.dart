import '../../../../core/error/result.dart';
import '../entities/tmb_peserta_entity.dart';
import '../repositories/tmb_repository.dart';

class GetTmbPesertaByTesUseCase {
  final TmbRepository _repository;
  const GetTmbPesertaByTesUseCase(this._repository);

  Future<Result<List<TmbPesertaEntity>>> call(int tesId) =>
      _repository.getPesertaByTes(tesId);
}
