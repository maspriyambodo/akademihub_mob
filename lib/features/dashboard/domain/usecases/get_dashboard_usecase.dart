import '../entities/dashboard_entity.dart';
import '../repositories/dashboard_repository.dart';

class GetDashboardDataUseCase {
  final DashboardRepository _repository;

  const GetDashboardDataUseCase(this._repository);

  Future<DashboardEntity> call() => _repository.getDashboardData();
}
