part of 'notifications_bloc.dart';

abstract class NotificationsEvent extends Equatable {
  const NotificationsEvent();

  @override
  List<Object?> get props => [];
}

/// Muat halaman pertama daftar notifikasi.
class NotificationsLoadRequested extends NotificationsEvent {
  const NotificationsLoadRequested();
}

/// Tarik ulang dari halaman pertama (pull-to-refresh).
class NotificationsRefreshRequested extends NotificationsEvent {
  const NotificationsRefreshRequested();
}

/// Muat halaman berikutnya (infinite scroll).
class NotificationsLoadMoreRequested extends NotificationsEvent {
  const NotificationsLoadMoreRequested();
}

/// Ganti tab filter: Semua / Belum dibaca.
class NotificationsFilterChanged extends NotificationsEvent {
  final NotificationFilter filter;
  const NotificationsFilterChanged(this.filter);

  @override
  List<Object?> get props => [filter];
}

/// Tandai satu notifikasi sudah dibaca (optimistic).
class NotificationMarkReadRequested extends NotificationsEvent {
  final int id;
  const NotificationMarkReadRequested(this.id);

  @override
  List<Object?> get props => [id];
}

/// Tandai semua notifikasi sudah dibaca (optimistic).
class NotificationsMarkAllReadRequested extends NotificationsEvent {
  const NotificationsMarkAllReadRequested();
}
