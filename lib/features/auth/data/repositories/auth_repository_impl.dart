import 'package:dio/dio.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../../../core/storage/token_storage.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final TokenStorage _tokenStorage;

  const AuthRepositoryImpl(this._remoteDataSource, this._tokenStorage);

  @override
  Future<Result<UserEntity>> login(String email, String password) async {
    try {
      final data = await _remoteDataSource.login(email, password);
      final token = data['access_token'] as String;
      final refreshToken = data['refresh_token'] as String?;
      await _tokenStorage.saveTokens(
        accessToken: token,
        refreshToken: refreshToken,
      );
      final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      return success(_userModelToEntity(user));
    } on DioException catch (e) {
      return fail(_mapException(mapDioException(e)));
    } on AppException catch (e) {
      return fail(_mapException(e));
    }
  }

  @override
  Future<Result<void>> logout() async {
    try {
      await _remoteDataSource.logout();
      await _tokenStorage.clearTokens();
      return success(null);
    } on DioException catch (e) {
      await _tokenStorage.clearTokens();
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
    }
  }

  UserEntity _userModelToEntity(UserModel model) => UserEntity(
    id: model.id,
    name: model.name,
    email: model.email,
    photo: model.photo,
    roles: model.roles,
    permissions: model.permissions,
    sekolahId: model.sekolahId,
    siswaId: model.siswaId,
    guruId: model.guruId,
    waliId: model.waliId,
  );

  Failure _mapException(AppException e) {
    if (e is NetworkException) return NetworkFailure(e.message);
    if (e is AuthException) return AuthFailure(e.message);
    if (e is ValidationException) {
      return ValidationFailure(e.message, errors: e.errors);
    }
    return ServerFailure(e.message);
  }
}
