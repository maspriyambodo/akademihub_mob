import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/absensi_bloc.dart';
import '../../domain/entities/absensi_siswa_entity.dart';
import '../../domain/entities/absensi_guru_entity.dart';
import '../../domain/entities/absensi_summary_entity.dart';

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
        final profileId = user.profile?['id'] as int?;
        context.read<AbsensiBloc>().add(
          AbsensiLoadRequested(
            role: user.role ?? 'admin',
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
      return; // jangan ke depan melebihi bulan ini
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
    return Scaffold(
      appBar: AppBar(title: const Text('Absensi'), centerTitle: true),
      body: Column(
        children: [
          // ── Month selector ─────────────────────────────────────────────
          _MonthSelector(
            bulan: _bulan,
            tahun: _tahun,
            onPrev: _prevMonth,
            onNext: _nextMonth,
          ),
          // ── Content ────────────────────────────────────────────────────
          Expanded(
            child: BlocBuilder<AbsensiBloc, AbsensiState>(
              builder: (context, state) {
                if (state is AbsensiLoading || state is AbsensiInitial) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is AbsensiError) {
                  return _ErrorView(
                    message: state.message,
                    onRetry: () => context.read<AbsensiBloc>().add(
                      const AbsensiRefreshRequested(),
                    ),
                  );
                }
                if (state is AbsensiLoaded) {
                  return _LoadedView(
                    state: state,
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
      color: AppColors.primary,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.white),
            onPressed: onPrev,
          ),
          Text(
            '${_bulanNames[bulan]} $tahun',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.chevron_right,
              color: isCurrentMonth ? Colors.white38 : Colors.white,
            ),
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
  final Future<void> Function() onRefresh;

  const _LoadedView({required this.state, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final items = state.isGuruMode ? state.guruItems : state.siswaItems;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: CustomScrollView(
        slivers: [
          // Summary cards
          SliverToBoxAdapter(child: _SummaryRow(summary: state.summary)),
          // List header
          if (items.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Text(
                  '${items.length} catatan',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          // Empty state
          if (items.isEmpty)
            SliverFillRemaining(
              child: _EmptyView(
                message: state.isGuruMode
                    ? 'Belum ada data absensi guru bulan ini'
                    : 'Belum ada data absensi bulan ini',
              ),
            )
          else if (state.isGuruMode)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => _AbsensiGuruCard(item: state.guruItems[i]),
                childCount: state.guruItems.length,
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => _AbsensiSiswaCard(item: state.siswaItems[i]),
                childCount: state.siswaItems.length,
              ),
            ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
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
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          _SummaryCard(
            label: 'Hadir',
            count: summary.hadir,
            color: AppColors.success,
          ),
          _SummaryCard(
            label: 'Izin',
            count: summary.izin,
            color: AppColors.info,
          ),
          _SummaryCard(
            label: 'Sakit',
            count: summary.sakit,
            color: AppColors.warning,
          ),
          _SummaryCard(
            label: 'Alpha',
            count: summary.alpha,
            color: AppColors.error,
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withAlpha(77)),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 11, color: color)),
          ],
        ),
      ),
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

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _statusColor(item.statusAbsensi).withAlpha(30),
          child: Text(
            date != null ? '${date.day}' : '-',
            style: TextStyle(
              color: _statusColor(item.statusAbsensi),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        title: Text(
          dateLabel,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        subtitle: item.keterangan != null && item.keterangan!.isNotEmpty
            ? Text(
                item.keterangan!,
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              )
            : null,
        trailing: _StatusBadge(label: item.statusAbsensi),
      ),
    );
  }

  Color _statusColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('hadir')) return AppColors.success;
    if (s.contains('izin')) return AppColors.info;
    if (s.contains('sakit')) return AppColors.warning;
    if (s.contains('alp')) return AppColors.error;
    return AppColors.textSecondary;
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

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _statusColor(item.statusAbsensi).withAlpha(30),
          child: Text(
            date != null ? '${date.day}' : '-',
            style: TextStyle(
              color: _statusColor(item.statusAbsensi),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        title: Text(
          dateLabel,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        subtitle: timeInfo.isNotEmpty
            ? Text(
                timeInfo,
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              )
            : null,
        trailing: _StatusBadge(label: item.statusAbsensi),
      ),
    );
  }

  Color _statusColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('hadir')) return AppColors.success;
    if (s.contains('izin')) return AppColors.info;
    if (s.contains('sakit')) return AppColors.warning;
    if (s.contains('alp')) return AppColors.error;
    return AppColors.textSecondary;
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

// ── Status Badge ──────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String label;
  const _StatusBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    final color = _color(label);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _color(String s) {
    final lower = s.toLowerCase();
    if (lower.contains('hadir')) return AppColors.success;
    if (lower.contains('izin')) return AppColors.info;
    if (lower.contains('sakit')) return AppColors.warning;
    if (lower.contains('alp')) return AppColors.error;
    return AppColors.textSecondary;
  }
}

// ── Error View ────────────────────────────────────────────────────────────────

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
            Icon(Icons.error_outline, size: 56, color: AppColors.error),
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

// ── Empty View ────────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  final String message;
  const _EmptyView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.how_to_reg_outlined, size: 64, color: AppColors.textHint),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
