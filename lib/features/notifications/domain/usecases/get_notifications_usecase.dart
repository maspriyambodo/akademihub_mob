import '../../../../core/error/result.dart';
import '../entities/notification_page_entity.dart';
import '../repositories/notifications_repository.dart';

class GetNotificationsUseCase {
  final NotificationsRepository _repository;
  const GetNotificationsUseCase(this._repository);

  Future<Result<NotificationPageEntity>> call({
    int page = 1,
    int perPage = 20,
  }) => _repository.getNotifications(page: page, perPage: perPage);
}
