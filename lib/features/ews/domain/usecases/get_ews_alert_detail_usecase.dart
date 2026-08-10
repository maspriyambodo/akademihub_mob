import '../../../../core/error/result.dart';
import '../entities/ews_alert_entity.dart';
import '../repositories/ews_repository.dart';

class GetEwsAlertDetailUseCase {
  final EwsRepository repository;

  const GetEwsAlertDetailUseCase(this.repository);

  Future<Result<EwsAlertEntity>> call(int id) {
    return repository.getAlertDetail(id);
  }
}
