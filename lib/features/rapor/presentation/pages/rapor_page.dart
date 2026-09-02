import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_surface_card.dart';
import '../../../../core/widgets/batas_lebar_konten.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/rapor_entity.dart';
import '../bloc/rapor_bloc.dart';
import 'rapor_detail_page.dart';
import 'rapor_form_page.dart';

class RaporPage extends StatelessWidget {
  const RaporPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<RaporBloc>(),
      child: const RaporView(),
    );
  }
}

class RaporView extends StatefulWidget {
  const RaporView({super.key});

  @override
  State<RaporView> createState() => _RaporViewState();
}

class _RaporViewState extends State<RaporView> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  String _role = '';
  bool _canExport = false;
  bool _canCreate = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authState = context.read<AuthBloc>().state;
      if (authState is! AuthAuthenticated) return;

      final user = authState.user;
      final role = user.role ?? 'unknown';
      final profileId = user.profile?['id'] as int?;

      setState(() {
        _role = role;
        _canExport = user.hasPermission('rapor.export');
        _canCreate = user.hasPermission('rapor.create');
      });

      context.read<RaporBloc>().add(
        RaporLoadRequested(
          role: role,
          profileId: profileId,
          canCreate: user.hasPermission('rapor.create'),
          canUpdate: user.hasPermission('rapor.update'),
          canDelete: user.hasPermission('rapor.delete'),
        ),
      );
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      context.read<RaporBloc>().add(RaporSearchChanged(value));
    });
  }

  void _openDetail(RaporEntity rapor) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RaporDetailPage(rapor: rapor, canExport: _canExport),
      ),
    );
  }

  Future<void> _openForm({
    RaporEntity? rapor,
    List<RaporEntity> pilihan = const [],
  }) async {
    final result = await Navigator.of(context).push<RaporFormResult>(
      MaterialPageRoute(
        builder: (_) => RaporFormPage(awal: rapor, pilihan: pilihan),
      ),
    );
    if (!mounted || result == null) return;
    final bloc = context.read<RaporBloc>();
    if (rapor == null) {
      bloc.add(
        RaporCreateRequested(
          siswaId: result.siswaId!,
          semester: result.semester!,
          catatanWali: result.catatanWali,
          sakit: result.sakit,
          izin: result.izin,
          tanpaKeterangan: result.tanpaKeterangan,
        ),
      );
    } else {
      bloc.add(
        RaporUpdateRequested(
          id: rapor.id,
          catatanWali: result.catatanWali,
          sakit: result.sakit,
          izin: result.izin,
          tanpaKeterangan: result.tanpaKeterangan,
        ),
      );
    }
  }

  Future<void> _delete(RaporEntity rapor) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus rapor?'),
        content: Text('Rapor ${rapor.labelPeriode} akan dihapus permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      context.read<RaporBloc>().add(RaporDeleteRequested(rapor.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final showSearch = _role.isNotEmpty && _role != 'siswa';

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(title: const Text('Rapor'), centerTitle: true),
      floatingActionButton: !_canCreate
          ? null
          : FloatingActionButton.extended(
              onPressed: () {
                final state = context.read<RaporBloc>().state;
                if (state is RaporLoaded) _openForm(pilihan: state.items);
              },
              icon: const Icon(Icons.add),
              label: const Text('Rapor Baru'),
            ),
      body: Column(
        children: [
          if (showSearch)
            _SearchField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              onClear: () {
                _searchController.clear();
                _onSearchChanged('');
              },
            ),
          Expanded(
            child: BlocConsumer<RaporBloc, RaporState>(
              listenWhen: (_, state) =>
                  state is RaporActionSuccess || state is RaporActionFailure,
              listener: (context, state) {
                final success = state is RaporActionSuccess;
                final message = success
                    ? state.message
                    : (state as RaporActionFailure).message;
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      content: Text(message),
                      backgroundColor: success
                          ? AppColors.success
                          : AppColors.error,
                    ),
                  );
              },
              buildWhen: (_, state) =>
                  state is! RaporActionSuccess && state is! RaporActionFailure,
              builder: (context, state) {
                if (state is RaporInitial || state is RaporLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is RaporError) {
                  return _ErrorView(
                    message: state.message,
                    onRetry: () => context.read<RaporBloc>().add(
                      const RaporRefreshRequested(),
                    ),
                  );
                }
                if (state is RaporLoaded) {
                  final pad = Responsive.pagePadding(context);
                  return BatasLebarKonten(
                    child: RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: () async {
                        context.read<RaporBloc>().add(
                          const RaporRefreshRequested(),
                        );
                      },
                      child: state.items.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                SizedBox(
                                  height: Responsive.tinggiSheet(
                                    context,
                                    rasio: 0.6,
                                  ),
                                  child: _EmptyView(
                                    message: state.search.isNotEmpty
                                        ? 'Tidak ada rapor yang cocok'
                                        : 'Belum ada data rapor',
                                  ),
                                ),
                              ],
                            )
                          : ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: EdgeInsets.fromLTRB(
                                pad.left,
                                AppSpacing.sm,
                                pad.right,
                                AppSpacing.xxl,
                              ),
                              itemCount: state.items.length,
                              itemBuilder: (_, i) {
                                final item = state.items[i];
                                return Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: AppSpacing.xs,
                                  ),
                                  child: _RaporCard(
                                    rapor: item,
                                    showSiswa: !state.isSiswaMode,
                                    onTap: () => _openDetail(item),
                                    onEdit: state.canUpdate
                                        ? () => _openForm(
                                            rapor: item,
                                            pilihan: state.items,
                                          )
                                        : null,
                                    onDelete: state.canDelete
                                        ? () => _delete(item)
                                        : null,
                                  ),
                                );
                              },
                            ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Search Field ─────────────────────────────────────────────────────────────

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final pagePadding = Responsive.pagePadding(context);
    return Container(
      color: AppColors.paperBright,
      padding: EdgeInsets.fromLTRB(
        pagePadding.left,
        AppSpacing.xs,
        pagePadding.right,
        AppSpacing.xs,
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Cari nama siswa...',
          prefixIcon: const Icon(
            Icons.search,
            size: 20,
            color: AppColors.inkMuted,
          ),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (_, value, child) => value.text.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: onClear,
                  ),
          ),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
        ),
      ),
    );
  }
}

// ── Rapor Card ───────────────────────────────────────────────────────────────

class _RaporCard extends StatelessWidget {
  final RaporEntity rapor;
  final bool showSiswa;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _RaporCard({
    required this.rapor,
    required this.showSiswa,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final rata = rapor.rataRata;
    final tone = _toneFromScore(rata);

    return AppSurfaceCard(
      onTap: onTap,
      accentColor: AppColors.semantic(tone).accent,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.semantic(tone).container,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  rata != null ? rata.toStringAsFixed(1) : '-',
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.semantic(tone).onContainer,
                  ),
                ),
                Text(
                  'Rata-rata',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: AppColors.semantic(tone).onContainer,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showSiswa) ...[
                  Text(
                    rapor.siswaNama ?? 'Siswa',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  rapor.labelPeriode,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: showSiswa ? 12 : 14,
                    fontWeight: showSiswa ? FontWeight.normal : FontWeight.w700,
                    color: showSiswa ? AppColors.inkSoft : AppColors.ink,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xxs,
                  children: [
                    if (rapor.kelas != null && rapor.kelas!.isNotEmpty)
                      _Chip(icon: Icons.school_outlined, label: rapor.kelas!),
                    if (rapor.siswaNis != null && showSiswa)
                      _Chip(
                        icon: Icons.badge_outlined,
                        label: 'NIS ${rapor.siswaNis}',
                      ),
                    if (rapor.peringkat != null)
                      _Chip(
                        icon: Icons.emoji_events_outlined,
                        label: 'Peringkat ${rapor.peringkat}',
                        accentColor: AppColors.secondary,
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (onEdit != null || onDelete != null)
            PopupMenuButton<String>(
              tooltip: 'Aksi rapor',
              onSelected: (action) {
                if (action == 'edit') onEdit?.call();
                if (action == 'delete') onDelete?.call();
              },
              itemBuilder: (_) => [
                if (onEdit != null)
                  const PopupMenuItem(value: 'edit', child: Text('Ubah')),
                if (onDelete != null)
                  const PopupMenuItem(value: 'delete', child: Text('Hapus')),
              ],
            ),
        ],
      ),
    );
  }
}

AppStatusTone _toneFromScore(double? score) {
  if (score == null) return AppStatusTone.neutral;
  if (score >= 85) return AppStatusTone.success;
  if (score >= 75) return AppStatusTone.info;
  if (score >= 60) return AppStatusTone.warning;
  return AppStatusTone.error;
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? accentColor;

  const _Chip({required this.icon, required this.label, this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: accentColor != null
            ? accentColor!.withValues(alpha: 0.12)
            : AppColors.paperMuted,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: accentColor ?? AppColors.inkMuted),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: accentColor ?? AppColors.inkSoft,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty / Error View ───────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  final String message;
  const _EmptyView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.description_outlined,
              size: 48,
              color: AppColors.inkMuted,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.inkSoft, fontSize: 14),
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
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: AppColors.errorContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 28,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Gagal Memuat Rapor',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              style: const TextStyle(color: AppColors.inkSoft, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
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
