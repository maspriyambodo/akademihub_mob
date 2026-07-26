import '../../../../core/error/result.dart';
import '../entities/kalender_harian_entity.dart';
import '../repositories/kalender_repository.dart';

class GetKalenderHarianUseCase {
  final KalenderRepository _repository;
  const GetKalenderHarianUseCase(this._repository);

  Future<Result<List<KalenderHarianEntity>>> call({int limit = 500}) =>
      _repository.getHarian(limit: limit);
}
