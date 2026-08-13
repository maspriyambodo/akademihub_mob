part of 'notifications_bloc.dart';

/// Tab filter pada halaman notifikasi.
enum NotificationFilter { semua, belumDibaca }

abstract class NotificationsState extends Equatable {
  const NotificationsState();

  @override
  List<Object?> get props => [];
}

class NotificationsInitial extends NotificationsState {
  const NotificationsInitial();
}

class NotificationsLoading extends NotificationsState {
  const NotificationsLoading();
}

class NotificationsLoaded extends NotificationsState {
  /// Semua item yang sudah ter-load (gabungan seluruh halaman), terbaru dulu.
  final List<NotificationEntity> items;

  final NotificationFilter filter;
  final int currentPage;
  final int lastPage;
  final int total;
  final int unreadCount;
  final bool isLoadingMore;

  /// Pesan error untuk aksi ringan (tandai dibaca / muat halaman berikutnya)
  /// yang cukup ditampilkan lewat SnackBar tanpa mengganti seluruh layar.
  final String? actionError;

  /// Dinaikkan setiap kali daftar berubah. `NotificationEntity` hanya
  /// membandingkan `id` pada `props`, jadi penanda ini yang memastikan
  /// state dianggap berbeda setelah optimistic update.
  final int revision;

  const NotificationsLoaded({
    required this.items,
    required this.filter,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    required this.unreadCount,
    this.isLoadingMore = false,
    this.actionError,
    required this.revision,
  });

  bool get hasMore => currentPage < lastPage;

  /// Item yang tampil sesuai tab aktif.
  List<NotificationEntity> get visibleItems =>
      filter == NotificationFilter.belumDibaca
      ? items.where((e) => !e.isRead).toList()
      : items;

  NotificationsLoaded copyWith({
    List<NotificationEntity>? items,
    NotificationFilter? filter,
    int? currentPage,
    int? lastPage,
    int? total,
    int? unreadCount,
    bool? isLoadingMore,
    String? actionError,
    int? revision,
  }) {
    return NotificationsLoaded(
      items: items ?? this.items,
      filter: filter ?? this.filter,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      total: total ?? this.total,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      // `actionError` sengaja tidak memakai fallback ke nilai lama supaya
      // pesan error tidak muncul berulang setelah ditampilkan sekali.
      actionError: actionError,
      revision: revision ?? this.revision,
    );
  }

  @override
  List<Object?> get props => [
    items,
    filter,
    currentPage,
    lastPage,
    total,
    unreadCount,
    isLoadingMore,
    actionError,
    revision,
  ];
}

class NotificationsError extends NotificationsState {
  final String message;
  const NotificationsError(this.message);

  @override
  List<Object?> get props => [message];
}
