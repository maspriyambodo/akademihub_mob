import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/notification_entity.dart';
import '../../domain/usecases/get_notifications_usecase.dart';
import '../../domain/usecases/get_unread_count_usecase.dart';
import '../../domain/usecases/mark_all_notifications_read_usecase.dart';
import '../../domain/usecases/mark_notification_read_usecase.dart';

part 'notifications_event.dart';
part 'notifications_state.dart';

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  final GetNotificationsUseCase getNotifications;
  final GetUnreadCountUseCase getUnreadCount;
  final MarkNotificationReadUseCase markNotificationRead;
  final MarkAllNotificationsReadUseCase markAllNotificationsRead;

  /// Backend membatasi `per_page` maksimal 100.
  static const int perPage = 20;

  NotificationFilter _filter = NotificationFilter.semua;
  int _revision = 0;

  NotificationsBloc({
    required this.getNotifications,
    required this.getUnreadCount,
    required this.markNotificationRead,
    required this.markAllNotificationsRead,
  }) : super(const NotificationsInitial()) {
    on<NotificationsLoadRequested>(_onLoad);
    on<NotificationsRefreshRequested>(_onRefresh);
    on<NotificationsLoadMoreRequested>(_onLoadMore);
    on<NotificationsFilterChanged>(_onFilterChanged);
    on<NotificationMarkReadRequested>(_onMarkRead);
    on<NotificationsMarkAllReadRequested>(_onMarkAllRead);
  }

  Future<void> _onLoad(
    NotificationsLoadRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    emit(const NotificationsLoading());
    await _fetchFirstPage(emit);
  }

  Future<void> _onRefresh(
    NotificationsRefreshRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    if (state is! NotificationsLoaded) {
      emit(const NotificationsLoading());
    }
    await _fetchFirstPage(emit);
  }

  Future<void> _fetchFirstPage(Emitter<NotificationsState> emit) async {
    final result = await getNotifications(page: 1, perPage: perPage);
    if (isClosed) return;
    if (result.isSuccess) {
      final page = result.requireData;
      emit(
        NotificationsLoaded(
          items: _sorted(page.items),
          filter: _filter,
          currentPage: page.currentPage,
          lastPage: page.lastPage,
          total: page.total,
          unreadCount: page.unreadCount,
          revision: ++_revision,
        ),
      );
    } else {
      emit(NotificationsError(result.requireFailure.message));
    }
  }

  Future<void> _onLoadMore(
    NotificationsLoadMoreRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    final current = state;
    if (current is! NotificationsLoaded) return;
    if (!current.hasMore || current.isLoadingMore) return;

    emit(current.copyWith(isLoadingMore: true, revision: ++_revision));

    final result = await getNotifications(
      page: current.currentPage + 1,
      perPage: perPage,
    );
    if (isClosed) return;

    if (result.isSuccess) {
      final page = result.requireData;
      final existingIds = current.items.map((e) => e.id).toSet();
      final merged = [
        ...current.items,
        ...page.items.where((e) => !existingIds.contains(e.id)),
      ];
      emit(
        current.copyWith(
          items: _sorted(merged),
          currentPage: page.currentPage,
          lastPage: page.lastPage,
          total: page.total,
          unreadCount: page.unreadCount,
          isLoadingMore: false,
          revision: ++_revision,
        ),
      );
    } else {
      emit(
        current.copyWith(
          isLoadingMore: false,
          actionError: result.requireFailure.message,
          revision: ++_revision,
        ),
      );
    }
  }

  void _onFilterChanged(
    NotificationsFilterChanged event,
    Emitter<NotificationsState> emit,
  ) {
    _filter = event.filter;
    final current = state;
    if (current is NotificationsLoaded) {
      emit(current.copyWith(filter: _filter, revision: ++_revision));
    }
  }

  Future<void> _onMarkRead(
    NotificationMarkReadRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    final current = state;
    if (current is! NotificationsLoaded) return;

    final index = current.items.indexWhere((e) => e.id == event.id);
    if (index == -1) return;

    final target = current.items[index];
    if (target.isRead) return; // sudah dibaca, tidak perlu apa-apa

    // ── Optimistic update ────────────────────────────────────────────────
    final optimistic = [...current.items];
    optimistic[index] = target.copyWith(isRead: true, readAt: DateTime.now());

    emit(
      current.copyWith(
        items: optimistic,
        unreadCount: current.unreadCount > 0 ? current.unreadCount - 1 : 0,
        revision: ++_revision,
      ),
    );

    final result = await markNotificationRead(event.id);
    if (isClosed) return;
    if (result.isFailure) {
      // Rollback ke kondisi sebelum optimistic update.
      final latest = state;
      if (latest is NotificationsLoaded) {
        final reverted = [...latest.items];
        final idx = reverted.indexWhere((e) => e.id == event.id);
        if (idx != -1) reverted[idx] = target;
        emit(
          latest.copyWith(
            items: reverted,
            unreadCount: latest.unreadCount + 1,
            actionError: result.requireFailure.message,
            revision: ++_revision,
          ),
        );
      }
      return;
    }

    // Sinkronkan jumlah belum dibaca dengan server (best effort).
    final countResult = await getUnreadCount();
    if (isClosed) return;
    final latest = state;
    if (countResult.isSuccess && latest is NotificationsLoaded) {
      emit(
        latest.copyWith(
          unreadCount: countResult.requireData,
          revision: ++_revision,
        ),
      );
    }
  }

  Future<void> _onMarkAllRead(
    NotificationsMarkAllReadRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    final current = state;
    if (current is! NotificationsLoaded) return;
    if (current.unreadCount == 0 && !current.items.any((e) => !e.isRead)) {
      return;
    }

    final now = DateTime.now();
    final previousItems = current.items;
    final previousUnread = current.unreadCount;

    // ── Optimistic update ────────────────────────────────────────────────
    emit(
      current.copyWith(
        items: previousItems
            .map((e) => e.isRead ? e : e.copyWith(isRead: true, readAt: now))
            .toList(),
        unreadCount: 0,
        revision: ++_revision,
      ),
    );

    final result = await markAllNotificationsRead();
    if (isClosed) return;
    if (result.isFailure) {
      final latest = state;
      if (latest is NotificationsLoaded) {
        emit(
          latest.copyWith(
            items: previousItems,
            unreadCount: previousUnread,
            actionError: result.requireFailure.message,
            revision: ++_revision,
          ),
        );
      }
    }
  }

  /// Terbaru dulu; item tanpa `created_at` ditaruh paling bawah.
  List<NotificationEntity> _sorted(List<NotificationEntity> items) {
    final sorted = [...items];
    sorted.sort((a, b) {
      final da = a.createdAt;
      final db = b.createdAt;
      if (da == null && db == null) return b.id.compareTo(a.id);
      if (da == null) return 1;
      if (db == null) return -1;
      final cmp = db.compareTo(da);
      return cmp != 0 ? cmp : b.id.compareTo(a.id);
    });
    return sorted;
  }
}
