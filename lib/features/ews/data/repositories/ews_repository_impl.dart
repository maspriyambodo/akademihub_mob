import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/ews_alert_entity.dart';
import '../../domain/repositories/ews_repository.dart';
import '../datasources/ews_remote_datasource.dart';

class EwsRepositoryImpl implements EwsRepository {
  final EwsRemoteDataSource _remote;

  const EwsRepositoryImpl(this._remote);

  @override
  Future<Result<List<EwsAlertEntity>>> getAlerts({
    int? siswaId,
    String? kategori,
    int? level,
    bool? isResolved,
  }) async {
    try {
      final models = await _remote.getAlerts(
        siswaId: siswaId,
        kategori: kategori,
        level: level,
        isResolved: isResolved,
      );
      return success(models.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    }
  }

  @override
  Future<Result<EwsAlertEntity>> getAlertDetail(int id) async {
    try {
      final model = await _remote.getAlertDetail(id);
      return success(model.toEntity());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    }
  }

  @override
  Future<Result<void>> resolveAlert(int id) async {
    try {
      await _remote.resolveAlert(id);
      return success(null);
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    }
  }

  @override
  Future<Result<void>> triggerCheck(int siswaId) async {
    try {
      await _remote.triggerCheck(siswaId);
      return success(null);
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    }
  }

  Failure _map(AppException e) {
    if (e is NetworkException) return NetworkFailure(e.message);
    if (e is AuthException) return AuthFailure(e.message);
    if (e is ForbiddenException) return ForbiddenFailure(e.message);
    if (e is NotFoundException) return NotFoundFailure(e.message);
    return ServerFailure(e.message);
  }
}
