import '../entities/dashboard_entity.dart';

abstract class DashboardRepository {
  Future<DashboardEntity> getDashboardData();
}
