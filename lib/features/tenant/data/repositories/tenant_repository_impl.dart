import 'package:dio/dio.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../datasources/tenant_remote_datasource.dart';
import '../../domain/entities/tenant_entity.dart';
import '../../domain/repositories/tenant_repository.dart';

class TenantRepositoryImpl implements TenantRepository {
  final TenantRemoteDataSource _remoteDataSource;

  const TenantRepositoryImpl(this._remoteDataSource);

  @override
  Future<Result<TenantEntity>> resolveTenant(String identifier) async {
    try {
      final model = await _remoteDataSource.resolveTenant(identifier);
      return success(model.toEntity());
    } on DioException catch (e) {
      return fail(_mapDio(mapDioException(e)));
    }
  }

  @override
  Future<Result<List<TenantEntity>>> listTenants({String? query}) async {
    try {
      final models = await _remoteDataSource.listTenants(query: query);
      return success(models.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      return fail(_mapDio(mapDioException(e)));
    }
  }

  Failure _mapDio(AppException e) {
    if (e is NetworkException) return NetworkFailure(e.message);
    if (e is NotFoundException) return NotFoundFailure(e.message);
    return ServerFailure(e.message);
  }
}
