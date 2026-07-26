import 'package:equatable/equatable.dart';

import 'notification_entity.dart';

/// Satu halaman hasil `GET /notifikasi` beserta metadata paginasinya.
class NotificationPageEntity extends Equatable {
  final List<NotificationEntity> items;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  /// Backend ikut mengirim `meta.unread_count` di endpoint daftar.
  final int unreadCount;

  const NotificationPageEntity({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
    required this.unreadCount,
  });

  bool get hasMore => currentPage < lastPage;

  @override
  List<Object?> get props => [
    items,
    currentPage,
    lastPage,
    perPage,
    total,
    unreadCount,
  ];
}
