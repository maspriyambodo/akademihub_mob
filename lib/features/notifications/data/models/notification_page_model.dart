import '../../domain/entities/notification_page_entity.dart';
import 'notification_model.dart';

/// Membungkus response `GET /notifikasi`:
/// ```json
/// { "success": true, "data": [ ... ],
///   "meta": { "total": 40, "per_page": 20, "current_page": 1,
///             "last_page": 2, "unread_count": 5 } }
/// ```
/// Tetap dibuat toleran kalau suatu saat `data` berupa objek paginator Laravel
/// (`{ "data": [...], "current_page": 1, ... }`).
class NotificationPageModel {
  final List<NotificationModel> items;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;
  final int unreadCount;

  const NotificationPageModel({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
    required this.unreadCount,
  });

  factory NotificationPageModel.fromResponse(
    Map<String, dynamic> response, {
    int fallbackPerPage = 20,
  }) {
    final raw = response['data'];

    final List<dynamic> list;
    if (raw is List) {
      list = raw;
    } else {
      list = (raw as Map<String, dynamic>?)?['data'] as List<dynamic>? ?? [];
    }

    // `meta` ada di root response; kalau tidak ada, coba ambil dari objek
    // paginator yang tersimpan di dalam `data`.
    Map<String, dynamic>? meta;
    if (response['meta'] is Map) {
      meta = (response['meta'] as Map).map((k, v) => MapEntry(k.toString(), v));
    } else if (raw is Map) {
      meta = raw.map((k, v) => MapEntry(k.toString(), v));
    }

    final items = list
        .whereType<Map<String, dynamic>>()
        .map(NotificationModel.fromJson)
        .toList();

    final unreadFromMeta = (meta?['unread_count'] as num?)?.toInt();

    return NotificationPageModel(
      items: items,
      currentPage: (meta?['current_page'] as num?)?.toInt() ?? 1,
      lastPage: (meta?['last_page'] as num?)?.toInt() ?? 1,
      perPage: (meta?['per_page'] as num?)?.toInt() ?? fallbackPerPage,
      total: (meta?['total'] as num?)?.toInt() ?? items.length,
      // Fallback: hitung dari item halaman ini bila meta tidak tersedia.
      unreadCount: unreadFromMeta ?? items.where((e) => !e.isRead).length,
    );
  }

  NotificationPageEntity toEntity() => NotificationPageEntity(
    items: items.map((m) => m.toEntity()).toList(),
    currentPage: currentPage,
    lastPage: lastPage,
    perPage: perPage,
    total: total,
    unreadCount: unreadCount,
  );
}
