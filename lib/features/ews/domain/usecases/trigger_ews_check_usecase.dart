import '../../../../core/error/result.dart';
import '../repositories/ews_repository.dart';

class TriggerEwsCheckUseCase {
  final EwsRepository repository;

  const TriggerEwsCheckUseCase(this.repository);

  Future<Result<void>> call(int siswaId) {
    return repository.triggerCheck(siswaId);
  }
}
