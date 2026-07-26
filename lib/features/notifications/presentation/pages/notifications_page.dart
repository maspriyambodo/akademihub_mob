import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/notification_entity.dart';
import '../bloc/notifications_bloc.dart';
import '../widgets/notification_detail_sheet.dart';
import '../widgets/notification_tile.dart';
import '../widgets/notification_visuals.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<NotificationsBloc>(),
      child: const _NotificationsView(),
    );
  }
}

class _NotificationsView extends StatefulWidget {
  const _NotificationsView();

  @override
  State<_NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<_NotificationsView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    // Locale Indonesia untuk `timeago`, didaftarkan di dalam fitur ini saja.
    ensureTimeagoIdLocale();

    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<NotificationsBloc>().add(
        const NotificationsLoadRequested(),
      );
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// Infinite scroll: muat halaman berikutnya saat mendekati ujung daftar.
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels < position.maxScrollExtent - 240) return;

    final bloc = context.read<NotificationsBloc>();
    final state = bloc.state;
    if (state is NotificationsLoaded &&
        state.hasMore &&
        !state.isLoadingMore) {
      bloc.add(const NotificationsLoadMoreRequested());
    }
  }

  Future<void> _onTapItem(NotificationEntity item) async {
    if (!item.isRead) {
      // Optimistic: bloc langsung menandai dibaca sebelum server merespons.
      context.read<NotificationsBloc>().add(
        NotificationMarkReadRequested(item.id),
      );
    }
    await NotificationDetailSheet.show(context, item);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        centerTitle: true,
        actions: [
          BlocBuilder<NotificationsBloc, NotificationsState>(
            builder: (context, state) {
              final unread = state is NotificationsLoaded
                  ? state.unreadCount
                  : 0;
              final enabled = unread > 0;
              return IconButton(
                tooltip: 'Tandai semua dibaca',
                icon: const Icon(Icons.done_all),
                color: enabled ? Colors.white : Colors.white54,
                onPressed: enabled
                    ? () => context.read<NotificationsBloc>().add(
                        const NotificationsMarkAllReadRequested(),
                      )
                    : null,
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<NotificationsBloc, NotificationsState>(
        listenWhen: (prev, curr) =>
            curr is NotificationsLoaded && curr.actionError != null,
        listener: (context, state) {
          if (state is NotificationsLoaded && state.actionError != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(state.actionError!),
                  backgroundColor: AppColors.error,
                ),
              );
          }
        },
        builder: (context, state) {
          if (state is NotificationsLoading || state is NotificationsInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is NotificationsError) {
            return _ErrorView(
              message: state.message,
              onRetry: () => context.read<NotificationsBloc>().add(
                const NotificationsLoadRequested(),
              ),
            );
          }

          if (state is NotificationsLoaded) {
            return Column(
              children: [
                _FilterBar(
                  filter: state.filter,
                  totalCount: state.items.length,
                  unreadCount: state.unreadCount,
                  onChanged: (f) => context.read<NotificationsBloc>().add(
                    NotificationsFilterChanged(f),
                  ),
                ),
                Expanded(
                  child: _LoadedView(
                    state: state,
                    scrollController: _scrollController,
                    onTapItem: _onTapItem,
                  ),
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

// ── Filter bar (Semua / Belum dibaca) ────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  final NotificationFilter filter;
  final int totalCount;
  final int unreadCount;
  final ValueChanged<NotificationFilter> onChanged;

  const _FilterBar({
    required this.filter,
    required this.totalCount,
    required this.unreadCount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.cardBg,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Row(
        children: [
          Expanded(
            child: _FilterButton(
              label: 'Semua',
              count: totalCount,
              selected: filter == NotificationFilter.semua,
              onTap: () => onChanged(NotificationFilter.semua),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _FilterButton(
              label: 'Belum dibaca',
              count: unreadCount,
              selected: filter == NotificationFilter.belumDibaca,
              onTap: () => onChanged(NotificationFilter.belumDibaca),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _FilterButton({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : AppColors.textSecondary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.divider,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 1,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withAlpha(60)
                      : AppColors.primary.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  count > 99 ? '99+' : '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : AppColors.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Daftar notifikasi ───────────────────────────────────────────────────────

class _LoadedView extends StatelessWidget {
  final NotificationsLoaded state;
  final ScrollController scrollController;
  final Future<void> Function(NotificationEntity) onTapItem;

  const _LoadedView({
    required this.state,
    required this.scrollController,
    required this.onTapItem,
  });

  @override
  Widget build(BuildContext context) {
    final items = state.visibleItems;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        context.read<NotificationsBloc>().add(
          const NotificationsRefreshRequested(),
        );
      },
      child: CustomScrollView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          if (items.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyView(
                message: state.filter == NotificationFilter.belumDibaca
                    ? 'Semua notifikasi sudah dibaca'
                    : 'Belum ada notifikasi',
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => NotificationTile(
                  item: items[i],
                  onTap: () => onTapItem(items[i]),
                ),
                childCount: items.length,
              ),
            ),
          if (state.isLoadingMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            )
          else if (items.isNotEmpty && !state.hasMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Center(
                  child: Text(
                    'Tidak ada notifikasi lain',
                    style: TextStyle(fontSize: 12, color: AppColors.textHint),
                  ),
                ),
              ),
            ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
        ],
      ),
    );
  }
}

// ── Error View ──────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty View ──────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  final String message;

  const _EmptyView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.notifications_none_outlined,
            size: 64,
            color: AppColors.textHint,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
