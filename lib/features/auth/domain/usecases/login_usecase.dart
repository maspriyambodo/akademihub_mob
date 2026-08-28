import '../../../../core/error/result.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository _repository;
  const LoginUseCase(this._repository);

  Future<Result<UserEntity>> call(String username, String password) =>
      _repository.login(username, password);
}
