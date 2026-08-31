import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../../domain/entities/dashboard_entity.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../datasources/dashboard_remote_datasource.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardRemoteDataSource _dataSource;

  const DashboardRepositoryImpl(this._dataSource);

  @override
  Future<DashboardEntity> getDashboardData() async {
    try {
      final model = await _dataSource.getDashboardData();
      return model.toEntity();
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }
}
