import '../../../../core/error/result.dart';
import '../entities/rapor_detail_entity.dart';
import '../repositories/rapor_repository.dart';

class GetRaporDetailUseCase {
  final RaporRepository _repository;
  const GetRaporDetailUseCase(this._repository);

  Future<Result<RaporDetailEntity>> call(int raporId) =>
      _repository.getRaporDetail(raporId);
}
