import '../../../../core/error/result.dart';
import '../entities/kalender_event_entity.dart';
import '../repositories/kalender_repository.dart';

class GetKalenderEventsUseCase {
  final KalenderRepository _repository;
  const GetKalenderEventsUseCase(this._repository);

  Future<Result<List<KalenderEventEntity>>> call({int limit = 500}) =>
      _repository.getEvents(limit: limit);
}
