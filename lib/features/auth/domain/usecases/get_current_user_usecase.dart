import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';
import '../../../../core/error/result.dart';

class GetCurrentUserUseCase {
  final AuthRepository _repository;
  const GetCurrentUserUseCase(this._repository);

  Future<Result<UserEntity>> call() => _repository.getCurrentUser();
}
