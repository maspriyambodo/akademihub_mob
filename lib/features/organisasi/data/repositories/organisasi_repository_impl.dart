import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/organisasi_detail_entity.dart';
import '../../domain/entities/organisasi_entity.dart';
import '../../domain/repositories/organisasi_repository.dart';
import '../datasources/organisasi_remote_datasource.dart';

class OrganisasiRepositoryImpl implements OrganisasiRepository {
  final OrganisasiRemoteDataSource _remote;

  const OrganisasiRepositoryImpl(this._remote);

  @override
  Future<Result<List<OrganisasiEntity>>> getOrganisasiList({
    String? status,
  }) async {
    try {
      final models = await _remote.getOrganisasiList(status: status);
      return success(models.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    } on AppException catch (e) {
      return fail(_map(e));
    }
  }

  @override
  Future<Result<OrganisasiDetailEntity>> getOrganisasiDetail(int id) async {
    try {
      final model = await _remote.getOrganisasiDetail(id);
      return success(model.toEntity());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    } on AppException catch (e) {
      return fail(_map(e));
    }
  }

  Failure _map(AppException e) {
    if (e is NetworkException) return NetworkFailure(e.message);
    if (e is AuthException) return AuthFailure(e.message);
    if (e is NotFoundException) return NotFoundFailure(e.message);
    return ServerFailure(e.message);
  }
}
