import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_section_header.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../../../core/widgets/app_surface_card.dart';
import '../../../../core/widgets/batas_lebar_konten.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/jadwal_bloc.dart';
import '../../domain/entities/jadwal_pelajaran_entity.dart';
import '../../../presensi/presentation/pages/quick_attendance_page.dart';

class JadwalPage extends StatelessWidget {
  const JadwalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<JadwalBloc>(),
      child: const JadwalView(),
    );
  }
}

class JadwalView extends StatefulWidget {
  const JadwalView({super.key});

  @override
  State<JadwalView> createState() => _JadwalViewState();
}

class _JadwalViewState extends State<JadwalView> {
  void _loadForUser(AuthAuthenticated state) {
    final user = state.user;
    final role = user.role ?? 'unknown';
    final profile = user.profile;
    final profileId = (profile?['id'] as num?)?.toInt();

    int? kelasId;
    if (role == 'siswa' || role == 'wali') {
      final kelas = profile?['kelas'];
      if (kelas is Map) {
        kelasId = (kelas['id'] as num?)?.toInt();
      }
      kelasId ??= (profile?['mst_kelas_id'] as num?)?.toInt();
      kelasId ??= (profile?['kelas_id'] as num?)?.toInt();
    }

    context.read<JadwalBloc>().add(
      JadwalLoadRequested(
        role: role,
        kelasId: kelasId,
        guruId: role == 'guru' ? profileId : null,
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated) _loadForUser(authState);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(title: const Text('Jadwal Pelajaran'), centerTitle: true),
      body: BlocListener<AuthBloc, AuthState>(
        listenWhen: (_, state) => state is AuthAuthenticated,
        listener: (context, state) {
          if (state is AuthAuthenticated) _loadForUser(state);
        },
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, authState) {
            if (authState is! AuthAuthenticated) {
              return const Center(child: CircularProgressIndicator());
            }

            return BlocBuilder<JadwalBloc, JadwalState>(
              builder: (context, state) {
                if (state is JadwalInitial || state is JadwalLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is JadwalError) {
                  return _ErrorView(
                    message: state.message,
                    onRetry: () => context.read<JadwalBloc>().add(
                      const JadwalRefreshRequested(),
                    ),
                  );
                }
                if (state is JadwalLoaded) {
                  return Column(
                    children: [
                      _HariSelector(
                        hariList: state.availableHari,
                        selected: state.selectedHari,
                        hariIni: hariCodeFromWeekday(state.now.weekday),
                        onSelected: (hari) => context.read<JadwalBloc>().add(
                          JadwalHariChanged(hari),
                        ),
                      ),
                      Expanded(
                        child: BatasLebarKonten(
                          child: RefreshIndicator(
                            color: AppColors.primary,
                            onRefresh: () async {
                              context.read<JadwalBloc>().add(
                                const JadwalRefreshRequested(),
                              );
                            },
                            child: state.items.isEmpty
                                ? _EmptyScrollView(
                                    message:
                                        'Tidak ada jadwal pelajaran pada hari '
                                        '${hariLabel(state.selectedHari)}',
                                  )
                                : _JadwalList(
                                    state: state,
                                    isGuru: authState.user.isGuru,
                                  ),
                          ),
                        ),
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            );
          },
        ),
      ),
    );
  }
}

// ── Selector Hari ────────────────────────────────────────────────────────────

class _HariSelector extends StatelessWidget {
  final List<String> hariList;
  final String selected;
  final String hariIni;
  final ValueChanged<String> onSelected;

  const _HariSelector({
    required this.hariList,
    required this.selected,
    required this.hariIni,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.paperBright,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        child: Row(
          children: hariList.map((hari) {
            final isSelected = hari == selected;
            final isToday = hari == hariIni;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: GestureDetector(
                onTap: () => onSelected(hari),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.paperMuted,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        hariLabelShort(hari),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : AppColors.inkSoft,
                        ),
                      ),
                      if (isToday) ...[
                        const SizedBox(width: 4),
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? Colors.white
                                : AppColors.primary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ── Daftar Jadwal ────────────────────────────────────────────────────────────

class _JadwalList extends StatelessWidget {
  final JadwalLoaded state;
  final bool isGuru;
  const _JadwalList({required this.state, required this.isGuru});

  @override
  Widget build(BuildContext context) {
    final pagePadding = Responsive.pagePadding(context);
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        pagePadding.left,
        AppSpacing.sm,
        pagePadding.right,
        AppSpacing.xxl,
      ),
      itemCount: state.items.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) return _ListHeader(state: state);
        final item = state.items[index - 1];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: _JadwalCard(
            item: item,
            now: state.now,
            isHariIni: state.isHariIni,
            showKelas: state.showKelas,
            isLast: index == state.items.length,
            canTakeAttendance: isGuru && state.isHariIni,
          ),
        );
      },
    );
  }
}

class _ListHeader extends StatelessWidget {
  final JadwalLoaded state;
  const _ListHeader({required this.state});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm, top: AppSpacing.xs),
      child: AppSectionHeader(
        title: hariLabel(state.selectedHari),
        eyebrow: 'Agenda Kelas',
        actionLabel: '${state.items.length} Mata Pelajaran',
      ),
    );
  }
}

// ── Kartu Jadwal ─────────────────────────────────────────────────────────────

class _JadwalCard extends StatelessWidget {
  final JadwalPelajaranEntity item;
  final DateTime now;
  final bool isHariIni;
  final bool showKelas;
  final bool isLast;
  final bool canTakeAttendance;

  const _JadwalCard({
    required this.item,
    required this.now,
    required this.isHariIni,
    required this.showKelas,
    required this.isLast,
    required this.canTakeAttendance,
  });

  @override
  Widget build(BuildContext context) {
    final berlangsung = isHariIni && item.isBerlangsung(now);
    final selesai = isHariIni && item.isSelesai(now);

    return Opacity(
      opacity: selesai ? 0.65 : 1.0,
      child: AppSurfaceCard(
        accentColor: berlangsung ? AppColors.success : null,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: berlangsung
                        ? AppColors.successContainer
                        : AppColors.primaryLight.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    item.jamMulai ?? '--:--',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: berlangsung
                          ? AppColors.successOnContainer
                          : AppColors.primaryDark,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    item.mapelNama ?? 'Mata Pelajaran',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (berlangsung)
                  const AppStatusBadge(
                    label: 'Berlangsung',
                    tone: AppStatusTone.success,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                const Icon(
                  Icons.person_outline,
                  size: 14,
                  color: AppColors.inkMuted,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    item.guruNama ?? 'Guru belum ditentukan',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.inkSoft,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xxs,
              children: [
                _JadwalChip(
                  icon: Icons.schedule_outlined,
                  label: item.durasiMenit != null
                      ? '${item.rentangJam} (${item.durasiMenit} mnt)'
                      : item.rentangJam,
                ),
                if (item.ruangan != null && item.ruangan!.isNotEmpty)
                  _JadwalChip(
                    icon: Icons.meeting_room_outlined,
                    label: item.ruangan!,
                  ),
                if (showKelas &&
                    item.kelasNama != null &&
                    item.kelasNama!.isNotEmpty)
                  _JadwalChip(
                    icon: Icons.school_outlined,
                    label: item.kelasNama!,
                  ),
              ],
            ),
            if (canTakeAttendance) ...[
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.fact_check_outlined, size: 18),
                  label: const Text('Presensi Cepat'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          QuickAttendancePage(jadwal: item, tanggal: now),
                    ),
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

class _JadwalChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _JadwalChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.paperMuted,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.inkMuted),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.inkSoft,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty / Error View ───────────────────────────────────────────────────────

class _EmptyScrollView extends StatelessWidget {
  final String message;
  const _EmptyScrollView({required this.message});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.event_busy_outlined,
                    size: 48,
                    color: AppColors.inkMuted,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.inkSoft,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
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
              'Gagal Memuat Jadwal',
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
