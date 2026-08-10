import '../../../../core/error/result.dart';
import '../entities/ews_alert_entity.dart';
import '../repositories/ews_repository.dart';

class GetEwsAlertsUseCase {
  final EwsRepository repository;

  const GetEwsAlertsUseCase(this.repository);

  Future<Result<List<EwsAlertEntity>>> call({
    int? siswaId,
    String? kategori,
    int? level,
    bool? isResolved,
  }) {
    return repository.getAlerts(
      siswaId: siswaId,
      kategori: kategori,
      level: level,
      isResolved: isResolved,
    );
  }
}
