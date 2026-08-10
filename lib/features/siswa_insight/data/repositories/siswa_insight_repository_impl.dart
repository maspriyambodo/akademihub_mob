import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/risk_profile_entity.dart';
import '../../domain/entities/siswa_insight_entity.dart';
import '../../domain/repositories/siswa_insight_repository.dart';
import '../datasources/siswa_insight_remote_datasource.dart';

class SiswaInsightRepositoryImpl implements SiswaInsightRepository {
  final SiswaInsightRemoteDataSource _remote;

  const SiswaInsightRepositoryImpl(this._remote);

  @override
  Future<Result<SiswaInsightEntity>> getInsight(
    int siswaId, {
    bool refresh = false,
  }) async {
    try {
      final model = await _remote.getInsight(siswaId, refresh: refresh);
      return success(model.toEntity());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    } catch (e) {
      return fail(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<RiskProfileEntity>> getRiskProfile(
    int siswaId, {
    bool refresh = false,
  }) async {
    try {
      final model = await _remote.getRiskProfile(siswaId, refresh: refresh);
      return success(model.toEntity());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    } catch (e) {
      return fail(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> getAcademicProgress(
    int siswaId, {
    bool refresh = false,
  }) async {
    try {
      final data = await _remote.getAcademicProgress(
        siswaId,
        refresh: refresh,
      );
      return success(data);
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    } catch (e) {
      return fail(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> invalidateCache(int siswaId) async {
    try {
      await _remote.invalidateCache(siswaId);
      return success(null);
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    } catch (e) {
      return fail(ServerFailure(e.toString()));
    }
  }

  Failure _map(AppException e) {
    if (e is NetworkException) return NetworkFailure(e.message);
    if (e is AuthException) return AuthFailure(e.message);
    if (e is NotFoundException) return NotFoundFailure(e.message);
    return ServerFailure(e.message);
  }
}
