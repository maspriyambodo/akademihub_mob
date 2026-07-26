import '../../../../core/error/result.dart';
import '../entities/kalender_tipe_entity.dart';
import '../repositories/kalender_repository.dart';

class GetKalenderTipeUseCase {
  final KalenderRepository _repository;
  const GetKalenderTipeUseCase(this._repository);

  Future<Result<List<KalenderTipeEntity>>> call() => _repository.getTipeList();
}
