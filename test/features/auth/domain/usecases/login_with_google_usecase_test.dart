import 'package:akademihub_mob/core/error/result.dart';
import 'package:akademihub_mob/features/auth/domain/entities/user_entity.dart';
import 'package:akademihub_mob/features/auth/domain/repositories/auth_repository.dart';
import 'package:akademihub_mob/features/auth/domain/usecases/login_with_google_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

class _MockAuthRepository implements AuthRepository {
  final UserEntity user;
  bool loginWithGoogleCalled = false;

  _MockAuthRepository(this.user);

  @override
  Future<Result<UserEntity>> login(String username, String password) async =>
      success(user);

  @override
  Future<Result<UserEntity>> loginWithGoogle() async {
    loginWithGoogleCalled = true;
    return success(user);
  }

  @override
  Future<Result<void>> logout() async => success(null);

  @override
  Future<Result<UserEntity>> getCurrentUser() async => success(user);
}

void main() {
  test('LoginWithGoogleUseCase calls repository.loginWithGoogle', () async {
    const user = UserEntity(
      id: 10,
      name: 'Google User',
      email: 'user@google.com',
      role: 'guru',
    );
    final repo = _MockAuthRepository(user);
    final useCase = LoginWithGoogleUseCase(repo);

    final result = await useCase();

    expect(repo.loginWithGoogleCalled, isTrue);
    expect(result.isSuccess, isTrue);
    expect(result.requireData.id, 10);
    expect(result.requireData.email, 'user@google.com');
  });
}
