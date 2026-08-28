import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
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
      child: const _JadwalView(),
    );
  }
}

class _JadwalView extends StatefulWidget {
  const _JadwalView();

  @override
  State<_JadwalView> createState() => _JadwalViewState();
}

class _JadwalViewState extends State<_JadwalView> {
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
                        child: Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: Responsive.lebarKontenMaks(context),
                            ),
                            child: RefreshIndicator(
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
      color: AppColors.primary,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: hariList.map((hari) {
            final isSelected = hari == selected;
            final isToday = hari == hariIni;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: GestureDetector(
                onTap: () => onSelected(hari),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : Colors.white24,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        hariLabelShort(hari),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? AppColors.primary : Colors.white,
                        ),
                      ),
                      if (isToday)
                        Container(
                          margin: const EdgeInsets.only(top: 3),
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? AppColors.primary
                                : Colors.white,
                          ),
                        ),
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
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      itemCount: state.items.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) return _ListHeader(state: state);
        final item = state.items[index - 1];
        return _JadwalCard(
          item: item,
          now: state.now,
          isHariIni: state.isHariIni,
          showKelas: state.showKelas,
          isLast: index == state.items.length,
          canTakeAttendance: isGuru && state.isHariIni,
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
    final hPad = Responsive.pagePadding(context).left;
    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 4),
      child: Row(
        children: [
          Flexible(
            child: Text(
              hariLabel(state.selectedHari),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (state.isHariIni)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(25),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Hari ini',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const Spacer(),
          const SizedBox(width: 8),
          Text(
            '${state.items.length} pelajaran',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Kartu Jadwal (timeline) ──────────────────────────────────────────────────

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
    this.canTakeAttendance = false,
  });

  @override
  Widget build(BuildContext context) {
    final berlangsung = isHariIni && item.isBerlangsung(now);
    final selesai = isHariIni && !berlangsung && item.isSelesai(now);

    final Color aksen = berlangsung
        ? AppColors.success
        : (selesai ? AppColors.textHint : AppColors.primary);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Kolom jam + garis timeline ────────────────────────────────
        SizedBox(
          width: Responsive.isCompact(context) ? 52 : 62,
          child: Column(
            children: [
              const SizedBox(height: 14),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  item.jamMulai ?? '--:--',
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: selesai ? AppColors.textHint : AppColors.textPrimary,
                  ),
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  item.jamSelesai ?? '--:--',
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
        _TimelineBar(color: aksen, aktif: berlangsung, isLast: isLast),
        // ── Kartu detail ──────────────────────────────────────────────
        Expanded(
          child: Opacity(
            opacity: selesai ? 0.6 : 1,
            child: Card(
              margin: EdgeInsets.fromLTRB(
                10,
                6,
                Responsive.pagePadding(context).right,
                6,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: berlangsung ? AppColors.success : AppColors.divider,
                  width: berlangsung ? 1.4 : 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.mapelNama ?? 'Mata pelajaran tidak diketahui',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (berlangsung) ...[
                          const SizedBox(width: 6),
                          const _BadgeBerlangsung(),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    _InfoRow(
                      icon: Icons.person_outline,
                      text: item.guruNama ?? 'Guru belum ditentukan',
                    ),
                    const SizedBox(height: 4),
                    LayoutBuilder(
                      builder: (context, c) => Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _Chip(
                            icon: Icons.schedule,
                            maxWidth: c.maxWidth,
                            label: item.durasiMenit != null
                                ? '${item.rentangJam} · ${item.durasiMenit} mnt'
                                : item.rentangJam,
                          ),
                          if (item.ruangan != null && item.ruangan!.isNotEmpty)
                            _Chip(
                              icon: Icons.meeting_room_outlined,
                              maxWidth: c.maxWidth,
                              label: item.ruangan!,
                            ),
                          if (showKelas &&
                              item.kelasNama != null &&
                              item.kelasNama!.isNotEmpty)
                            _Chip(
                              icon: Icons.class_outlined,
                              maxWidth: c.maxWidth,
                              label: item.kelasNama!,
                            ),
                        ],
                      ),
                    ),
                    if (canTakeAttendance) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.fact_check_outlined),
                          label: const Text('Quick Attendance'),
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => QuickAttendancePage(
                                jadwal: item,
                                tanggal: now,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TimelineBar extends StatelessWidget {
  final Color color;
  final bool aktif;
  final bool isLast;

  const _TimelineBar({
    required this.color,
    required this.aktif,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      child: Column(
        children: [
          Container(width: 2, height: 14, color: AppColors.divider),
          Container(
            width: aktif ? 14 : 10,
            height: aktif ? 14 : 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              border: aktif
                  ? Border.all(color: AppColors.cardBg, width: 2)
                  : null,
            ),
          ),
          SizedBox(
            height: 112,
            child: Container(
              width: 2,
              color: isLast ? Colors.transparent : AppColors.divider,
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeBerlangsung extends StatelessWidget {
  const _BadgeBerlangsung();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.success.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.success.withAlpha(120)),
      ),
      child: const Text(
        'Berlangsung',
        style: TextStyle(
          fontSize: 10,
          color: AppColors.success,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;

  /// Batas lebar chip agar label panjang tidak meluber keluar `Wrap`.
  final double? maxWidth;

  const _Chip({required this.icon, required this.label, this.maxWidth});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: maxWidth != null && maxWidth!.isFinite
            ? maxWidth!
            : double.infinity,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
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
              Icons.event_busy_outlined,
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

/// Pembungkus [_EmptyView] agar tetap bisa ditarik (pull-to-refresh)
/// walaupun kontennya tidak melebihi tinggi layar.
class _EmptyScrollView extends StatelessWidget {
  final String message;
  const _EmptyScrollView({required this.message});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: _EmptyView(message: message),
          ),
        );
      },
    );
  }
}
