import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/batas_lebar_konten.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../materi/presentation/pages/akademik_publikasi_form_page.dart';
import '../../domain/entities/tugas_entity.dart';
import '../bloc/tugas_bloc.dart';
import '../widgets/tugas_widgets.dart';
import 'pengumpulan_tugas_page.dart';
import 'tugas_detail_page.dart';

class TugasPage extends StatelessWidget {
  const TugasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<TugasBloc>(),
      child: const TugasView(),
    );
  }
}

class TugasView extends StatefulWidget {
  const TugasView({super.key});

  @override
  State<TugasView> createState() => _TugasViewState();
}

class _TugasViewState extends State<TugasView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authState = context.read<AuthBloc>().state;
      if (authState is! AuthAuthenticated) return;

      final user = authState.user;
      final role = user.role ?? 'unknown';
      final profile = user.profile;
      final profileId = user.profileId;

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
          canSubmit: user.hasPermission('tugas-siswa.create'),
        ),
      );
    });
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

  bool _bolehBuat(BuildContext context) {
    final auth = context.read<AuthBloc>().state;
    return auth is AuthAuthenticated && auth.user.hasPermission('tugas.create');
  }

  bool _milikGuruSaatIni(BuildContext context, TugasEntity tugas) {
    final auth = context.read<AuthBloc>().state;
    final guruId = auth is AuthAuthenticated
        ? (auth.user.profile?['id'] as num?)?.toInt()
        : null;
    return guruId != null && tugas.guruId == guruId;
  }

  bool _bolehUbah(BuildContext context, TugasEntity tugas) {
    final auth = context.read<AuthBloc>().state;
    return auth is AuthAuthenticated &&
        auth.user.hasPermission('tugas.update') &&
        _milikGuruSaatIni(context, tugas);
  }

  bool _bolehHapus(BuildContext context, TugasEntity tugas) {
    final auth = context.read<AuthBloc>().state;
    return auth is AuthAuthenticated &&
        auth.user.hasPermission('tugas.delete') &&
        _milikGuruSaatIni(context, tugas);
  }

  Future<void> _tambahTugas() async {
    final dibuat = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            AkademikPublikasiFormPage(type: AkademikPublikasiType.tugas),
      ),
    );
    if (dibuat == true && mounted) {
      context.read<TugasBloc>().add(const TugasRefreshRequested());
    }
  }

  Future<void> _ubahTugas(TugasEntity tugas) async {
    final disimpan = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AkademikPublikasiFormPage(
          type: AkademikPublikasiType.tugas,
          publicationId: tugas.id,
          guruMapelId: tugas.guruMapelId,
          kelasId: tugas.kelasId,
          judul: tugas.judul,
          deskripsi: tugas.deskripsi,
          filePath: tugas.fileLampiran,
          tenggat: tugas.tenggatWaktuDate,
        ),
      ),
    );
    if (disimpan == true && mounted) {
      context.read<TugasBloc>().add(const TugasRefreshRequested());
    }
  }

  Future<void> _hapusTugas(TugasEntity tugas) async {
    final hapus = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus tugas?'),
        content: Text('"${tugas.judul}" akan dihapus permanen.'),
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
    if (hapus != true || !mounted) return;
    try {
      await sl<ApiClient>().dio.delete('/akademik/tugas/${tugas.id}');
      if (!mounted) return;
      context.read<TugasBloc>().add(const TugasRefreshRequested());
    } on DioException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error.response?.data is Map
                  ? error.response!.data['message']?.toString() ??
                        'Gagal menghapus tugas'
                  : 'Gagal menghapus tugas',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
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
            final pagePadding = Responsive.pagePadding(context);
            return Column(
              children: [
                if (state.isSiswaMode || state.isWaliMode)
                  _FilterBar(state: state),
                Expanded(
                  child: BatasLebarKonten(
                    child: RefreshIndicator(
                      color: AppColors.primary,
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
                              padding: EdgeInsets.fromLTRB(
                                pagePadding.left,
                                AppSpacing.xs,
                                pagePadding.right,
                                AppSpacing.xxl,
                              ),
                              itemCount: state.items.length,
                              itemBuilder: (context, index) => Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.xs,
                                ),
                                child: TugasCard(
                                  item: state.items[index],
                                  showStatus:
                                      state.isSiswaMode || state.isWaliMode,
                                  onTap: () =>
                                      _openDetail(context, state, index),
                                  onEdit:
                                      _bolehUbah(
                                        context,
                                        state.items[index].tugas,
                                      )
                                      ? () =>
                                            _ubahTugas(state.items[index].tugas)
                                      : null,
                                  onDelete:
                                      _bolehHapus(
                                        context,
                                        state.items[index].tugas,
                                      )
                                      ? () => _hapusTugas(
                                          state.items[index].tugas,
                                        )
                                      : null,
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
      floatingActionButton: _bolehBuat(context)
          ? FloatingActionButton.extended(
              onPressed: _tambahTugas,
              icon: const Icon(Icons.add),
              label: const Text('Tugas'),
            )
          : null,
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
      decoration: const BoxDecoration(
        color: AppColors.paperBright,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                _FilterChip(
                  label: 'Belum (${state.totalBelum})',
                  selected: state.filter == TugasFilter.belum,
                  onTap: () => context.read<TugasBloc>().add(
                    const TugasFilterChanged(TugasFilter.belum),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                _FilterChip(
                  label: 'Sudah (${state.totalSudah})',
                  selected: state.filter == TugasFilter.sudah,
                  onTap: () => context.read<TugasBloc>().add(
                    const TugasFilterChanged(TugasFilter.sudah),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                _FilterChip(
                  label: 'Semua (${state.totalSemua})',
                  selected: state.filter == TugasFilter.semua,
                  onTap: () => context.read<TugasBloc>().add(
                    const TugasFilterChanged(TugasFilter.semua),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs + 2,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.paperMuted,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.inkSoft,
          ),
        ),
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
              Icons.assignment_turned_in_outlined,
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
              'Gagal Memuat Tugas',
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
