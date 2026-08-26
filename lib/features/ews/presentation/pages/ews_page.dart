import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/batas_lebar_konten.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/ews_alert_entity.dart';
import '../bloc/ews_bloc.dart';
import '../widgets/ews_alert_tile.dart';

/// Permission backend untuk modul EWS.
const String ewsPermView = 'ews.view';
const String ewsPermManage = 'ews.manage';

class EwsPage extends StatelessWidget {
  const EwsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: (_) => sl<EwsBloc>(), child: const _EwsView());
  }
}

class _EwsView extends StatefulWidget {
  const _EwsView();

  @override
  State<_EwsView> createState() => _EwsViewState();
}

class _EwsViewState extends State<_EwsView> {
  bool _canView = false;
  bool _canManage = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = context.read<AuthBloc>().state;
      if (auth is! AuthAuthenticated) {
        return;
      }
      final user = auth.user;
      _canView = user.hasPermission(ewsPermView);
      _canManage = user.hasPermission(ewsPermManage);
      if (_canView) context.read<EwsBloc>().add(const EwsLoadRequested());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Early Warning System'),
        centerTitle: true,
      ),
      body: BlocConsumer<EwsBloc, EwsState>(
        listenWhen: (prev, curr) =>
            curr is EwsLoaded && curr.actionMessage != null,
        listener: (context, state) {
          if (state is EwsLoaded && state.actionMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.actionMessage!),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
        builder: (context, state) {
          if (!_canView) {
            return _NoAccessView();
          }
          if (state is EwsLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is EwsError) {
            return _ErrorView(
              message: state.message,
              onRetry: () =>
                  context.read<EwsBloc>().add(const EwsRefreshRequested()),
            );
          }
          if (state is EwsLoaded) {
            return _LoadedView(
              items: state.items,
              kategori: state.kategori,
              level: state.level,
              onlyUnresolved: state.onlyUnresolved,
              canManage: _canManage,
              onRefresh: () async {
                context.read<EwsBloc>().add(const EwsRefreshRequested());
                await Future<void>.delayed(Duration.zero);
              },
              onFilter: (kategori, level, onlyUnresolved) =>
                  context.read<EwsBloc>().add(
                    EwsFilterChanged(
                      kategori: kategori,
                      level: level,
                      onlyUnresolved: onlyUnresolved,
                    ),
                  ),
              onResolve: (id) =>
                  context.read<EwsBloc>().add(EwsResolveRequested(id)),
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}

class _LoadedView extends StatelessWidget {
  final List<EwsAlertEntity> items;
  final String? kategori;
  final int? level;
  final bool? onlyUnresolved;
  final bool canManage;
  final Future<void> Function() onRefresh;
  final void Function(String? kategori, int? level, bool? onlyUnresolved)
  onFilter;
  final void Function(int id) onResolve;

  const _LoadedView({
    required this.items,
    required this.kategori,
    required this.level,
    required this.onlyUnresolved,
    required this.canManage,
    required this.onRefresh,
    required this.onFilter,
    required this.onResolve,
  });

  @override
  Widget build(BuildContext context) {
    final pad = context.pagePadding;
    final active = items.where((e) => !e.isResolved).length;
    final resolved = items.length - active;

    return Column(
      children: [
        BatasLebarKonten(
          child: Column(
            children: [
              _SummaryBar(active: active, resolved: resolved),
              _FilterBar(
                kategori: kategori,
                level: level,
                onlyUnresolved: onlyUnresolved ?? false,
                onChanged: onFilter,
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: onRefresh,
            child: items.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: Responsive.tinggiSheet(context, rasio: 0.55),
                        child: const _EmptyView(
                          message: 'Tidak ada alert EWS yang cocok.',
                        ),
                      ),
                    ],
                  )
                : BatasLebarKonten(
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        pad.left,
                        8,
                        pad.right,
                        pad.bottom + 24,
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, i) {
                        final item = items[i];
                        return EwsAlertTile(
                          alert: item,
                          onResolve: !item.isResolved && canManage
                              ? () => onResolve(item.id)
                              : null,
                        );
                      },
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _SummaryBar extends StatelessWidget {
  final int active;
  final int resolved;

  const _SummaryBar({required this.active, required this.resolved});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: _SummaryCard(
              icon: Icons.warning_amber,
              label: 'Aktif',
              value: active.toString(),
              color: AppColors.error,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _SummaryCard(
              icon: Icons.check_circle,
              label: 'Selesai',
              value: resolved.toString(),
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withAlpha(40),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.bodyMedium),
                  Text(value, style: Theme.of(context).textTheme.titleLarge),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final String? kategori;
  final int? level;
  final bool onlyUnresolved;
  final void Function(String? kategori, int? level, bool? onlyUnresolved)
  onChanged;

  const _FilterBar({
    required this.kategori,
    required this.level,
    required this.onlyUnresolved,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _FilterChip(
              label: onlyUnresolved ? 'Aktif saja' : 'Semua status',
              selected: onlyUnresolved,
              onTap: () => onChanged(kategori, level, !onlyUnresolved),
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: 'Kategori: ${_kategoriLabel(kategori)}',
              selected: kategori != null,
              onTap: () => _showKategoriPicker(context),
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: level == null ? 'Level: Semua' : 'Level: $level',
              selected: level != null,
              onTap: () => _showLevelPicker(context),
            ),
          ],
        ),
      ),
    );
  }

  String _kategoriLabel(String? k) {
    switch (k) {
      case 'absensi':
        return 'Kehadiran';
      case 'nilai':
        return 'Akademik';
      case 'perilaku':
        return 'Perilaku';
      default:
        return 'Semua';
    }
  }

  void _showKategoriPicker(BuildContext context) async {
    final selected = await showModalBottomSheet<String?>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Semua'),
              onTap: () => Navigator.pop(context, null),
            ),
            ListTile(
              title: const Text('Kehadiran'),
              onTap: () => Navigator.pop(context, 'absensi'),
            ),
            ListTile(
              title: const Text('Akademik'),
              onTap: () => Navigator.pop(context, 'nilai'),
            ),
            ListTile(
              title: const Text('Perilaku'),
              onTap: () => Navigator.pop(context, 'perilaku'),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted) return;
    onChanged(selected, level, onlyUnresolved);
  }

  void _showLevelPicker(BuildContext context) async {
    final selected = await showModalBottomSheet<int?>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Semua'),
              onTap: () => Navigator.pop(context, null),
            ),
            ListTile(
              title: const Text('Level 1 — Ringan'),
              onTap: () => Navigator.pop(context, 1),
            ),
            ListTile(
              title: const Text('Level 2 — Sedang'),
              onTap: () => Navigator.pop(context, 2),
            ),
            ListTile(
              title: const Text('Level 3 — Berat'),
              onTap: () => Navigator.pop(context, 3),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted) return;
    onChanged(kategori, selected, onlyUnresolved);
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final String message;
  const _EmptyView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.warning_amber_outlined,
              size: 56,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 56, color: AppColors.error),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
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

class _NoAccessView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 56, color: AppColors.textHint),
            const SizedBox(height: 12),
            Text(
              'Anda tidak memiliki izin untuk melihat modul EWS.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
