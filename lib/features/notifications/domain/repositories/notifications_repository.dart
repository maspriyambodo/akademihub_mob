import '../../../../core/error/result.dart';
import '../entities/notification_entity.dart';
import '../entities/notification_page_entity.dart';

abstract class NotificationsRepository {
  /// GET /notifikasi — daftar notifikasi milik user login (terpaginasi).
  Future<Result<NotificationPageEntity>> getNotifications({
    int page = 1,
    int perPage = 20,
  });

  /// GET /notifikasi/unread-count — jumlah notifikasi belum dibaca.
  Future<Result<int>> getUnreadCount();

  /// PUT /notifikasi/{id}/read — tandai satu notifikasi sudah dibaca.
  Future<Result<NotificationEntity>> markAsRead(int id);

  /// POST /notifikasi/read-all — tandai semua sudah dibaca.
  /// Mengembalikan jumlah baris yang ter-update.
  Future<Result<int>> markAllAsRead();
}
