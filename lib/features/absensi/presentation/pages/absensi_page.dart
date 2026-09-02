import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_metric_tile.dart';
import '../../../../core/widgets/app_section_header.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../../../core/widgets/app_surface_card.dart';
import '../../../../core/widgets/batas_lebar_konten.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/absensi_bloc.dart';
import '../../domain/entities/absensi_siswa_entity.dart';
import '../../domain/entities/absensi_guru_entity.dart';
import '../../domain/entities/absensi_summary_entity.dart';
import '../../data/services/attendance_location_service.dart';

class AbsensiPage extends StatelessWidget {
  const AbsensiPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AbsensiBloc>(),
      child: const _AbsensiView(),
    );
  }
}

class _AbsensiView extends StatefulWidget {
  const _AbsensiView();

  @override
  State<_AbsensiView> createState() => _AbsensiViewState();
}

class _AbsensiViewState extends State<_AbsensiView> {
  late int _bulan;
  late int _tahun;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _bulan = now.month;
    _tahun = now.year;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated) {
        final user = authState.user;
        final profileId = user.profileId;
        context.read<AbsensiBloc>().add(
          AbsensiLoadRequested(
            role: user.role ?? 'unknown',
            profileId: profileId,
            bulan: _bulan,
            tahun: _tahun,
          ),
        );
      }
    });
  }

  void _prevMonth() {
    setState(() {
      if (_bulan == 1) {
        _bulan = 12;
        _tahun--;
      } else {
        _bulan--;
      }
    });
    context.read<AbsensiBloc>().add(
      AbsensiMonthChanged(bulan: _bulan, tahun: _tahun),
    );
  }

  void _nextMonth() {
    final now = DateTime.now();
    if (_tahun > now.year || (_tahun == now.year && _bulan >= now.month)) {
      return;
    }
    setState(() {
      if (_bulan == 12) {
        _bulan = 1;
        _tahun++;
      } else {
        _bulan++;
      }
    });
    context.read<AbsensiBloc>().add(
      AbsensiMonthChanged(bulan: _bulan, tahun: _tahun),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = (context.watch<AuthBloc>().state as AuthAuthenticated?)?.user;
    final isSiswa = user?.role == 'siswa';

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        title: Text(isSiswa ? 'Riwayat Absensi Saya' : 'Absensi'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _MonthSelector(
            bulan: _bulan,
            tahun: _tahun,
            onPrev: _prevMonth,
            onNext: _nextMonth,
          ),
          Expanded(
            child: BlocConsumer<AbsensiBloc, AbsensiState>(
              listener: (context, state) {
                if (state is AbsensiLoaded && state.mutationMessage != null) {
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      SnackBar(
                        content: Text(state.mutationMessage!),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                }
              },
              listenWhen: (prev, curr) {
                final prevMsg = prev is AbsensiLoaded
                    ? prev.mutationMessage
                    : null;
                final currMsg = curr is AbsensiLoaded
                    ? curr.mutationMessage
                    : null;
                return currMsg != null && currMsg != prevMsg;
              },
              builder: (context, state) {
                if (state is AbsensiLoading || state is AbsensiInitial) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is AbsensiError) {
                  return _ErrorView(
                    message: state.message,
                    settingsTarget: state.settingsTarget,
                    showContactOfficer: state.showContactOfficer,
                    onRetry: () => context.read<AbsensiBloc>().add(
                      const AbsensiRefreshRequested(),
                    ),
                  );
                }
                final loaded = state is AbsensiActionInProgress
                    ? state.previous
                    : state is AbsensiLoaded
                    ? state
                    : null;
                if (loaded != null) {
                  return _LoadedView(
                    state: loaded,
                    isSiswa: isSiswa,
                    actionInProgress: state is AbsensiActionInProgress,
                    onRefresh: () async {
                      context.read<AbsensiBloc>().add(
                        const AbsensiRefreshRequested(),
                      );
                    },
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

// ── Month Selector ──────────────────────────────────────────────────────────

class _MonthSelector extends StatelessWidget {
  final int bulan;
  final int tahun;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _MonthSelector({
    required this.bulan,
    required this.tahun,
    required this.onPrev,
    required this.onNext,
  });

  static const _bulanNames = [
    '',
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isCurrentMonth = bulan == now.month && tahun == now.year;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.paperBright,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.isCompact(context)
            ? AppSpacing.xs
            : AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: AppColors.ink),
            tooltip: 'Bulan sebelumnya',
            onPressed: onPrev,
          ),
          Expanded(
            child: Text(
              '${_bulanNames[bulan]} $tahun',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.chevron_right,
              color: isCurrentMonth
                  ? AppColors.inkMuted.withValues(alpha: 0.3)
                  : AppColors.ink,
            ),
            tooltip: 'Bulan berikutnya',
            onPressed: isCurrentMonth ? null : onNext,
          ),
        ],
      ),
    );
  }
}

// ── Loaded View ──────────────────────────────────────────────────────────────

class _LoadedView extends StatelessWidget {
  final AbsensiLoaded state;
  final bool isSiswa;
  final Future<void> Function() onRefresh;
  final bool actionInProgress;

  const _LoadedView({
    required this.state,
    required this.isSiswa,
    required this.onRefresh,
    this.actionInProgress = false,
  });

  @override
  Widget build(BuildContext context) {
    final items = state.isGuruMode ? state.guruItems : state.siswaItems;
    final pagePadding = Responsive.pagePadding(context);
    final now = DateTime.now();
    final isCurrentMonth = state.bulan == now.month && state.tahun == now.year;

    return BatasLebarKonten(
      child: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: onRefresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            if (isSiswa && isCurrentMonth)
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  pagePadding.left,
                  AppSpacing.md,
                  pagePadding.right,
                  0,
                ),
                sliver: SliverToBoxAdapter(
                  child: _CheckInPanel(
                    attendance: state.currentAttendance,
                    actionInProgress: actionInProgress,
                  ),
                ),
              ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                pagePadding.left,
                AppSpacing.md,
                pagePadding.right,
                0,
              ),
              sliver: SliverToBoxAdapter(
                child: _SummaryRow(summary: state.summary),
              ),
            ),
            if (items.isNotEmpty)
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  pagePadding.left,
                  AppSpacing.md,
                  pagePadding.right,
                  AppSpacing.xs,
                ),
                sliver: SliverToBoxAdapter(
                  child: AppSectionHeader(
                    title: 'Riwayat Kehadiran',
                    eyebrow: 'Log Presensi',
                    actionLabel: '${items.length} Catatan',
                  ),
                ),
              ),
            if (items.isEmpty)
              SliverFillRemaining(
                child: _EmptyView(
                  message: state.isGuruMode
                      ? 'Belum ada data absensi guru bulan ini'
                      : 'Belum ada data absensi bulan ini',
                ),
              )
            else if (state.isGuruMode)
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: pagePadding.left),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: _AbsensiGuruCard(item: state.guruItems[i]),
                    ),
                    childCount: state.guruItems.length,
                  ),
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: pagePadding.left),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: _AbsensiSiswaCard(item: state.siswaItems[i]),
                    ),
                    childCount: state.siswaItems.length,
                  ),
                ),
              ),
            const SliverPadding(
              padding: EdgeInsets.only(bottom: AppSpacing.xxl),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckInPanel extends StatelessWidget {
  final AbsensiSiswaEntity? attendance;
  final bool actionInProgress;

  const _CheckInPanel({
    required this.attendance,
    required this.actionInProgress,
  });

  @override
  Widget build(BuildContext context) {
    final a = attendance;
    final checkedIn = a?.jamMasuk != null;
    final checkedOut = a?.jamPulang != null;
    final isFinalStatus =
        a != null &&
        !a.statusAbsensi.toLowerCase().contains('hadir') &&
        a.statusAbsensi.isNotEmpty;

    final waitingForCheckout = checkedIn && !checkedOut && !isFinalStatus;
    bool checkoutTimeReached = true;
    if (waitingForCheckout && a?.jadwalJamPulang != null) {
      final now = TimeOfDay.now();
      final parts = a!.jadwalJamPulang!.split(':');
      if (parts.length >= 2) {
        final schedHour = int.tryParse(parts[0]) ?? 0;
        final schedMin = int.tryParse(parts[1]) ?? 0;
        checkoutTimeReached =
            now.hour > schedHour ||
            (now.hour == schedHour && now.minute >= schedMin);
      }
    }

    final String label;
    final Color color;
    final IconData icon;
    final bool actionEnabled;
    final String buttonLabel;
    final bool isCheckOut;

    if (isFinalStatus) {
      label = 'Status: ${a.statusAbsensi}';
      color = AppColors.warning;
      icon = Icons.info_outline;
      actionEnabled = false;
      buttonLabel = a.statusAbsensi;
      isCheckOut = false;
    } else if (checkedOut) {
      label = 'Absensi hari ini selesai';
      color = AppColors.success;
      icon = Icons.check_circle_outline;
      actionEnabled = false;
      buttonLabel = 'Selesai';
      isCheckOut = false;
    } else if (waitingForCheckout && !checkoutTimeReached) {
      final shift = a?.shiftNama ?? 'Shift';
      final pulang = a?.jadwalJamPulang ?? '-';
      final tz = a?.timezone;
      label =
          '$shift • Check-in ${a!.jamMasuk}\n'
          'Pulang mulai $pulang${tz != null ? ' ($tz)' : ''}';
      color = AppColors.success;
      icon = Icons.schedule_outlined;
      actionEnabled = false;
      buttonLabel = 'Menunggu';
      isCheckOut = true;
    } else if (checkedIn) {
      final shift = a?.shiftNama ?? 'Shift';
      label = '$shift • Check-in ${a!.jamMasuk}';
      color = AppColors.success;
      icon = Icons.check_circle_outline;
      actionEnabled = !actionInProgress;
      buttonLabel = 'Check-out';
      isCheckOut = true;
    } else {
      label = 'Belum check-in hari ini';
      color = AppColors.primary;
      icon = Icons.how_to_reg_outlined;
      actionEnabled = !actionInProgress;
      buttonLabel = 'Check-in';
      isCheckOut = false;
    }

    return AppSurfaceCard(
      accentColor: color,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
          ),
          FilledButton(
            onPressed: actionEnabled
                ? () => context.read<AbsensiBloc>().add(
                    isCheckOut
                        ? const AbsensiCheckOutRequested()
                        : const AbsensiCheckInRequested(),
                  )
                : null,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            ),
            child: actionInProgress
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(buttonLabel),
          ),
        ],
      ),
    );
  }
}

// ── Summary Row ──────────────────────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  final AbsensiSummaryEntity summary;
  const _SummaryRow({required this.summary});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < Responsive.compactWidth;
        final tiles = [
          AppMetricTile(
            label: 'Hadir',
            value: '${summary.hadir}',
            icon: Icons.check_circle_outline,
            tone: AppStatusTone.success,
          ),
          AppMetricTile(
            label: 'Izin',
            value: '${summary.izin}',
            icon: Icons.info_outline,
            tone: AppStatusTone.info,
          ),
          AppMetricTile(
            label: 'Sakit',
            value: '${summary.sakit}',
            icon: Icons.local_hospital_outlined,
            tone: AppStatusTone.warning,
          ),
          AppMetricTile(
            label: 'Alpha',
            value: '${summary.alpha}',
            icon: Icons.highlight_off,
            tone: AppStatusTone.error,
          ),
        ];

        if (isCompact) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: tiles[0]),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(child: tiles[1]),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Expanded(child: tiles[2]),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(child: tiles[3]),
                ],
              ),
            ],
          );
        }

        return Row(
          children: [
            for (int i = 0; i < tiles.length; i++) ...[
              if (i > 0) const SizedBox(width: AppSpacing.xs),
              Expanded(child: tiles[i]),
            ],
          ],
        );
      },
    );
  }
}

// ── Absensi Siswa Card ────────────────────────────────────────────────────────

class _AbsensiSiswaCard extends StatelessWidget {
  final AbsensiSiswaEntity item;
  const _AbsensiSiswaCard({required this.item});

  static const _dayNames = [
    '',
    'Sen',
    'Sel',
    'Rab',
    'Kam',
    'Jum',
    'Sab',
    'Min',
  ];

  @override
  Widget build(BuildContext context) {
    final date = item.tanggalDate;
    final dayLabel = date != null ? _dayNames[date.weekday] : '';
    final dateLabel = date != null
        ? '$dayLabel, ${date.day} ${_monthShort(date.month)} ${date.year}'
        : item.tanggal;

    final tone = _toneFromStatus(item.statusAbsensi);

    return AppSurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.semantic(tone).container,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Center(
              child: Text(
                date != null ? '${date.day}' : '-',
                style: TextStyle(
                  color: AppColors.semantic(tone).onContainer,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                if (item.keterangan != null && item.keterangan!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.keterangan!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.inkSoft,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          AppStatusBadge(label: item.statusAbsensi, tone: tone),
        ],
      ),
    );
  }

  static const _months = [
    '',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  String _monthShort(int m) => _months[m];
}

// ── Absensi Guru Card ─────────────────────────────────────────────────────────

class _AbsensiGuruCard extends StatelessWidget {
  final AbsensiGuruEntity item;
  const _AbsensiGuruCard({required this.item});

  static const _dayNames = [
    '',
    'Sen',
    'Sel',
    'Rab',
    'Kam',
    'Jum',
    'Sab',
    'Min',
  ];

  @override
  Widget build(BuildContext context) {
    final date = item.tanggalDate;
    final dayLabel = date != null ? _dayNames[date.weekday] : '';
    final dateLabel = date != null
        ? '$dayLabel, ${date.day} ${_monthShort(date.month)} ${date.year}'
        : item.tanggal;

    final timeInfo = [
      if (item.jamMasuk != null) 'Masuk: ${item.jamMasuk}',
      if (item.jamKeluar != null) 'Keluar: ${item.jamKeluar}',
    ].join('  ·  ');

    final tone = _toneFromStatus(item.statusAbsensi);

    return AppSurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.semantic(tone).container,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Center(
              child: Text(
                date != null ? '${date.day}' : '-',
                style: TextStyle(
                  color: AppColors.semantic(tone).onContainer,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                if (timeInfo.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    timeInfo,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.inkSoft,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          AppStatusBadge(label: item.statusAbsensi, tone: tone),
        ],
      ),
    );
  }

  static const _months = [
    '',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  String _monthShort(int m) => _months[m];
}

AppStatusTone _toneFromStatus(String status) {
  final s = status.toLowerCase();
  if (s.contains('hadir')) return AppStatusTone.success;
  if (s.contains('izin')) return AppStatusTone.info;
  if (s.contains('sakit')) return AppStatusTone.warning;
  if (s.contains('alp')) return AppStatusTone.error;
  return AppStatusTone.neutral;
}

// ── Empty View ───────────────────────────────────────────────────────────────

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
              Icons.event_busy_outlined,
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

// ── Error View ───────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final AttendanceSettingsTarget? settingsTarget;
  final bool showContactOfficer;
  final VoidCallback onRetry;

  const _ErrorView({
    required this.message,
    required this.settingsTarget,
    required this.showContactOfficer,
    required this.onRetry,
  });

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
              'Gagal Memuat Absensi',
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
