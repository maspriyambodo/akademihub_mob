import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/tugas_bloc.dart';
import '../widgets/tugas_widgets.dart';
import 'tugas_detail_page.dart';
import 'pengumpulan_tugas_page.dart';

class TugasPage extends StatelessWidget {
  const TugasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<TugasBloc>(),
      child: const _TugasView(),
    );
  }
}

class _TugasView extends StatefulWidget {
  const _TugasView();

  @override
  State<_TugasView> createState() => _TugasViewState();
}

class _TugasViewState extends State<_TugasView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authState = context.read<AuthBloc>().state;
      if (authState is! AuthAuthenticated) return;

      final user = authState.user;
      final role = _normalizeRole(user.role);
      final profile = user.profile;
      final profileId = (profile?['id'] as num?)?.toInt();

      final kelasRaw = profile?['kelas'];
      final kelasId = kelasRaw is Map
          ? (kelasRaw['id'] as num?)?.toInt()
          : null;

      final guruMapelId =
          (profile?['mst_guru_mapel_id'] as num?)?.toInt() ??
          (profile?['guru_mapel_id'] as num?)?.toInt();

      context.read<TugasBloc>().add(
        TugasLoadRequested(
          role: role,
          siswaId: role == 'siswa' ? profileId : null,
          kelasId: kelasId,
          guruId: role == 'guru' ? profileId : null,
          guruMapelId: role == 'guru' ? guruMapelId : null,
        ),
      );
    });
  }

  /// Kode role backend bisa berupa 'SISWA'/'GURU'/'WALI_SISWA'/'admin'.
  String _normalizeRole(String? raw) {
    final r = (raw ?? '').toLowerCase();
    if (r.contains('wali')) return 'wali';
    if (r.contains('guru')) return 'guru';
    if (r.contains('siswa')) return 'siswa';
    return 'admin';
  }

  void _openDetail(BuildContext context, TugasLoaded state, int index) {
    final item = state.items[index];
    final bloc = context.read<TugasBloc>();

    if (state.isGuruMode) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PengumpulanTugasPage(tugas: item.tugas),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: bloc,
          child: TugasDetailPage(tugasId: item.tugas.id),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tugas'), centerTitle: true),
      body: BlocConsumer<TugasBloc, TugasState>(
        listenWhen: (_, current) =>
            current is TugasActionSuccess || current is TugasActionFailure,
        listener: (context, state) {
          final messenger = ScaffoldMessenger.of(context);
          if (state is TugasActionSuccess) {
            messenger.showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.success,
              ),
            );
          } else if (state is TugasActionFailure) {
            messenger.showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        buildWhen: (_, current) =>
            current is! TugasActionSuccess && current is! TugasActionFailure,
        builder: (context, state) {
          if (state is TugasInitial || state is TugasLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is TugasError) {
            return _ErrorView(
              message: state.message,
              onRetry: () =>
                  context.read<TugasBloc>().add(const TugasRefreshRequested()),
            );
          }
          if (state is TugasLoaded) {
            return Column(
              children: [
                if (state.isSiswaMode || state.isWaliMode)
                  _FilterBar(state: state),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: Responsive.lebarKontenMaks(context),
                      ),
                      child: RefreshIndicator(
                        onRefresh: () async {
                          context.read<TugasBloc>().add(
                            const TugasRefreshRequested(),
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
                                      message: _emptyMessage(state),
                                    ),
                                  ),
                                ],
                              )
                            : ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.only(
                                  top: 6,
                                  bottom: 20,
                                ),
                                itemCount: state.items.length,
                                itemBuilder: (context, index) => TugasCard(
                                  item: state.items[index],
                                  showStatus:
                                      state.isSiswaMode || state.isWaliMode,
                                  onTap: () =>
                                      _openDetail(context, state, index),
                                ),
                              ),
                      ),
                    ),
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

  String _emptyMessage(TugasLoaded state) {
    if (state.isGuruMode) return 'Belum ada tugas yang Anda buat';
    return switch (state.filter) {
      TugasFilter.belum => 'Tidak ada tugas yang belum dikumpulkan',
      TugasFilter.sudah => 'Belum ada tugas yang dikumpulkan',
      TugasFilter.semua => 'Belum ada tugas',
    };
  }
}

// ── Filter Bar ───────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  final TugasLoaded state;
  const _FilterBar({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.isCompact(context) ? 8 : 12,
        vertical: 10,
      ),
      child: Row(
        children: [
          _FilterChip(
            label: 'Semua',
            count: state.totalSemua,
            selected: state.filter == TugasFilter.semua,
            filter: TugasFilter.semua,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Belum',
            count: state.totalBelum,
            selected: state.filter == TugasFilter.belum,
            filter: TugasFilter.belum,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Sudah',
            count: state.totalSudah,
            selected: state.filter == TugasFilter.sudah,
            filter: TugasFilter.sudah,
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final TugasFilter filter;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.filter,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.read<TugasBloc>().add(TugasFilterChanged(filter)),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.divider,
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '$label ($count)',
              maxLines: 1,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Error View ───────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: Responsive.pagePadding(context) + const EdgeInsets.all(16),
      child: Center(
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

// ── Empty View ───────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  final String message;
  const _EmptyView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: Responsive.pagePadding(context) + const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.assignment_outlined,
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
      ),
    );
  }
}
