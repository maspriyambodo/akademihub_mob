import '../../../../core/error/result.dart';
import '../repositories/notifications_repository.dart';

class GetUnreadCountUseCase {
  final NotificationsRepository _repository;
  const GetUnreadCountUseCase(this._repository);

  Future<Result<int>> call() => _repository.getUnreadCount();
}
