import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../../core/storage/answer_outbox.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final TokenStorage _tokenStorage;
  final ApiClient _apiClient;
  final AnswerOutbox _answerOutbox;

  AuthRepositoryImpl(
    this._remoteDataSource,
    this._tokenStorage,
    this._apiClient,
    this._answerOutbox,
  );

  @override
  Future<Result<UserEntity>> login(String username, String password) async {
    try {
      final data = await _remoteDataSource.login(username, password);
      final token = data['access_token'] as String;
      final refreshToken = data['refresh_token'] as String?;
      final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      await _tokenStorage.saveTokens(
        accessToken: token,
        refreshToken: refreshToken,
        origin: AppConfig.extractOrigin(_apiClient.dio.options.baseUrl),
      );
      return success(_userModelToEntity(user));
    } on DioException catch (e) {
      return fail(_mapException(mapDioException(e)));
    } on AppException catch (e) {
      return fail(_mapException(e));
    } on Object {
      return fail(const ServerFailure('Format respons login tidak valid'));
    }
  }

  @override
  Future<Result<void>> logout() async {
    try {
      await _remoteDataSource.logout();
      await _tokenStorage.clearTokens();
      await _answerOutbox.clear();
      return success(null);
    } on DioException catch (e) {
      await _tokenStorage.clearTokens();
      await _answerOutbox.clear();
      return fail(_mapException(mapDioException(e)));
    }
  }

  @override
  Future<Result<UserEntity>> getCurrentUser() async {
    try {
      final user = await _remoteDataSource.getCurrentUser();
      return success(_userModelToEntity(user));
    } on DioException catch (e) {
      return fail(_mapException(mapDioException(e)));
    } on Object {
      return fail(const ServerFailure('Format respons pengguna tidak valid'));
    }
  }

  UserEntity _userModelToEntity(UserModel model) => UserEntity(
    id: model.id,
    name: model.name,
    email: model.email,
    role: model.normalizedRole,
    isActive: model.isActive,
    permissions: model.permissions,
    profile: model.profile,
  );

  Failure _mapException(AppException e) {
    if (e is NetworkException) return NetworkFailure(e.message);
    if (e is AuthException) return AuthFailure(e.message);
    if (e is ForbiddenException) return ForbiddenFailure(e.message);
    if (e is ValidationException) {
      return ValidationFailure(e.message, errors: e.errors);
    }
    return ServerFailure(e.message);
  }
}
