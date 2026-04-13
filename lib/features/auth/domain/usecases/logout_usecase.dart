import '../repositories/auth_repository.dart';
import '../../../../core/error/result.dart';

class LogoutUseCase {
  final AuthRepository _repository;
  const LogoutUseCase(this._repository);

  Future<Result<void>> call() => _repository.logout();
}
