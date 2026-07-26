import '../../../../core/error/result.dart';
import '../repositories/notifications_repository.dart';

class MarkAllNotificationsReadUseCase {
  final NotificationsRepository _repository;
  const MarkAllNotificationsReadUseCase(this._repository);

  Future<Result<int>> call() => _repository.markAllAsRead();
}
