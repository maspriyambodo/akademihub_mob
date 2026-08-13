import '../../../../core/error/result.dart';
import '../entities/notification_entity.dart';
import '../repositories/notifications_repository.dart';

class MarkNotificationReadUseCase {
  final NotificationsRepository _repository;
  const MarkNotificationReadUseCase(this._repository);

  Future<Result<NotificationEntity>> call(int id) => _repository.markAsRead(id);
}
