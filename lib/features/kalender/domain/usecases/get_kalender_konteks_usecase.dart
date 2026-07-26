import '../../../../core/error/result.dart';
import '../entities/kalender_konteks_entity.dart';
import '../repositories/kalender_repository.dart';

class GetKalenderKonteksUseCase {
  final KalenderRepository _repository;
  const GetKalenderKonteksUseCase(this._repository);

  Future<Result<KalenderKonteksEntity>> call() => _repository.getKonteks();
}
