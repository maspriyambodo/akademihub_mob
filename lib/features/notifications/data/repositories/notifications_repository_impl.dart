import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/entities/notification_page_entity.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../datasources/notifications_remote_datasource.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  final NotificationsRemoteDataSource _remote;

  const NotificationsRepositoryImpl(this._remote);

  @override
  Future<Result<NotificationPageEntity>> getNotifications({
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final model = await _remote.getNotifications(
        page: page,
        perPage: perPage,
      );
      return success(model.toEntity());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    }
  }

  @override
  Future<Result<int>> getUnreadCount() async {
    try {
      return success(await _remote.getUnreadCount());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    }
  }

  @override
  Future<Result<NotificationEntity>> markAsRead(int id) async {
    try {
      final model = await _remote.markAsRead(id);
      if (model == null) {
        return fail(const ServerFailure('Notifikasi gagal ditandai dibaca'));
      }
      return success(model.toEntity());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    }
  }

  @override
  Future<Result<int>> markAllAsRead() async {
    try {
      return success(await _remote.markAllAsRead());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    }
  }

  Failure _map(AppException e) {
    if (e is NetworkException) return NetworkFailure(e.message);
    if (e is AuthException) return AuthFailure(e.message);
    if (e is ForbiddenException) return ForbiddenFailure(e.message);
    if (e is NotFoundException) return NotFoundFailure(e.message);
    return ServerFailure(e.message);
  }
}
