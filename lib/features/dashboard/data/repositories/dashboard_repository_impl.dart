import '../../domain/entities/dashboard_entity.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../datasources/dashboard_remote_datasource.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardRemoteDataSource _dataSource;

  const DashboardRepositoryImpl(this._dataSource);

  @override
  Future<DashboardEntity> getDashboardData() async {
    final model = await _dataSource.getDashboardData();
    return model.toEntity();
  }
}
