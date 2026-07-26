import '../../../../core/error/result.dart';
import '../entities/tmb_pertanyaan_entity.dart';
import '../repositories/tmb_repository.dart';

class GetTmbPertanyaanUseCase {
  final TmbRepository _repository;
  const GetTmbPertanyaanUseCase(this._repository);

  Future<Result<List<TmbPertanyaanEntity>>> call(
    int tesId, {
    required bool viaTesDetail,
  }) => _repository.getPertanyaan(tesId, viaTesDetail: viaTesDetail);
}
