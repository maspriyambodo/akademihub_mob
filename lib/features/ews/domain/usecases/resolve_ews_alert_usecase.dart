import '../../../../core/error/result.dart';
import '../repositories/ews_repository.dart';

class ResolveEwsAlertUseCase {
  final EwsRepository repository;

  const ResolveEwsAlertUseCase(this.repository);

  Future<Result<void>> call(int id) {
    return repository.resolveAlert(id);
  }
}
