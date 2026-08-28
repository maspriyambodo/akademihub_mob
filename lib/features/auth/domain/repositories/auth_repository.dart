import '../../../../core/error/result.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<Result<UserEntity>> login(String username, String password);
  Future<Result<void>> logout();
  Future<Result<UserEntity>> getCurrentUser();
}
