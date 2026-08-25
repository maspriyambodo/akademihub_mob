import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/batas_lebar_konten.dart';
import '../../domain/entities/siswa_insight_entity.dart';
import '../bloc/siswa_insight_bloc.dart';

class SiswaInsightPage extends StatelessWidget {
  final int siswaId;

  const SiswaInsightPage({super.key, required this.siswaId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<SiswaInsightBloc>()..add(InsightLoadRequested(siswaId)),
      child: const _InsightView(),
    );
  }
}

class _InsightView extends StatefulWidget {
  const _InsightView();

  @override
  State<_InsightView> createState() => _InsightViewState();
}

class _InsightViewState extends State<_InsightView> {
  int? _lastSiswaId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Insight 360°'),
        centerTitle: true,
        actions: [
          BlocBuilder<SiswaInsightBloc, SiswaInsightState>(
            builder: (context, state) {
              if (state is! SiswaInsightLoaded) return const SizedBox.shrink();
              return IconButton(
                tooltip: 'Refresh data',
                icon: const Icon(Icons.refresh),
                onPressed: () => context.read<SiswaInsightBloc>().add(
                  const InsightRefreshRequested(),
                ),
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<SiswaInsightBloc, SiswaInsightState>(
        listenWhen: (prev, curr) =>
            curr is SiswaInsightLoaded && curr.actionMessage != null,
        listener: (context, state) {
          if (state is SiswaInsightLoaded) {
            _lastSiswaId = state.siswaId;
            final msg = state.actionMessage;
            if (msg != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(msg),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          }
        },
        builder: (context, state) {
          if (state is SiswaInsightInitial || state is SiswaInsightLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is SiswaInsightError) {
            final id = _lastSiswaId;
            return _ErrorView(
              message: state.message,
              onRetry: id == null
                  ? null
                  : () {
                      context.read<SiswaInsightBloc>().add(
                        InsightLoadRequested(id),
                      );
                    },
            );
          }
          if (state is SiswaInsightLoaded) {
            return _LoadedView(state: state);
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}

class _LoadedView extends StatelessWidget {
  final SiswaInsightLoaded state;

  const _LoadedView({required this.state});

  static const _tabs = <String>[
    'Overview',
    'Profil Risiko',
    'Akademik',
    'Kehadiran',
    'Keuangan',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _HeaderCard(insight: state.insight),
        Container(
          color: AppColors.cardBg,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: List.generate(_tabs.length, (i) {
                final selected = state.activeTab == i;
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 6,
                  ),
                  child: ChoiceChip(
                    label: Text(_tabs[i]),
                    selected: selected,
                    onSelected: (_) => context.read<SiswaInsightBloc>().add(
                      InsightTabChanged(i),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
        Expanded(
          child: BatasLebarKonten(
            child: IndexedStack(
              index: state.activeTab,
              children: [
                _OverviewTab(insight: state.insight),
                _RiskProfileTab(insight: state.insight),
                _AcademicTab(insight: state.insight),
                _AttendanceTab(insight: state.insight),
                _FinanceTab(insight: state.insight),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final SiswaInsightEntity insight;

  const _HeaderCard({required this.insight});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      color: AppColors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            insight.namaSiswa,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            [
              if (insight.nis != null) 'NIS: ${insight.nis}',
              if (insight.kelas != null) insight.kelas,
              if (insight.status != null) insight.status,
            ].join(' · '),
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _ResponsiveRow extends StatelessWidget {
  final List<Widget> children;

  const _ResponsiveRow({required this.children});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= Responsive.compactWidth) {
          return Row(children: children);
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children.map((child) {
            if (child is Expanded) return child.child;
            if (child is SizedBox && child.width != null) {
              return SizedBox(height: child.width);
            }
            return child;
          }).toList(),
        );
      },
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final SiswaInsightEntity insight;

  const _OverviewTab({required this.insight});

  @override
  Widget build(BuildContext context) {
    final pad = context.pagePadding;
    return ListView(
      padding: EdgeInsets.fromLTRB(pad.left, 12, pad.right, pad.bottom + 24),
      children: [
        _ResponsiveRow(
          children: [
            Expanded(
              child: _SummaryCard(
                title: 'Kehadiran',
                value: _pct(insight.kehadiranSummary?['pct_hadir']),
                subtitle:
                    (insight.kehadiranSummary?['status'] as String? ?? '-'),
                color: AppColors.success,
                icon: Icons.event_available,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SummaryCard(
                title: 'Tugas',
                value: _pct(insight.tugasSummary?['pct_kumpul']),
                subtitle: (insight.tugasSummary?['status'] as String? ?? '-'),
                color: AppColors.info,
                icon: Icons.assignment_turned_in,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _ResponsiveRow(
          children: [
            Expanded(
              child: _SummaryCard(
                title: 'SPP',
                value: (insight.sppSummary?['status'] as String? ?? '-'),
                subtitle: insight.sppSummary?['tunggakan'] != null
                    ? 'Tunggakan: ${insight.sppSummary!['tunggakan']} bulan'
                    : null,
                color: AppColors.warning,
                icon: Icons.account_balance_wallet,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SummaryCard(
                title: 'EWS',
                value: (insight.ewsSummary?['status'] as String? ?? '-'),
                subtitle: insight.ewsSummary?['total_aktif'] != null
                    ? 'Alert aktif: ${insight.ewsSummary!['total_aktif']}'
                    : null,
                color: AppColors.error,
                icon: Icons.warning_amber,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Aktivitas 30 hari terakhir',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        _Heatmap(activity: insight.activityHeatmap),
      ],
    );
  }

  String _pct(dynamic v) {
    if (v == null) return '-';
    if (v is num) return '${v.toStringAsFixed(1)}%';
    return v.toString();
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withAlpha(40),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(value, style: Theme.of(context).textTheme.titleLarge),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(subtitle!, style: Theme.of(context).textTheme.labelSmall),
            ],
          ],
        ),
      ),
    );
  }
}

class _Heatmap extends StatelessWidget {
  final Map<String, dynamic> activity;

  const _Heatmap({required this.activity});

  int _maxValue() {
    var max = 0;
    for (final v in activity.values) {
      if (v is num && v.toInt() > max) max = v.toInt();
    }
    return max == 0 ? 1 : max;
  }

  @override
  Widget build(BuildContext context) {
    final entries = activity.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    if (entries.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Belum ada aktivitas tercatat',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }
    final maxVal = _maxValue();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 4,
          runSpacing: 4,
          children: entries.map((e) {
            final v = (e.value is num) ? (e.value as num).toInt() : 0;
            final intensity = v == 0 ? 0.0 : (v / maxVal).clamp(0.15, 1.0);
            return Tooltip(
              message: '${e.key}: $v',
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: AppColors.success.withAlpha((intensity * 255).round()),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _RiskProfileTab extends StatelessWidget {
  final SiswaInsightEntity insight;

  const _RiskProfileTab({required this.insight});

  static const _dimensionLabels = {
    'akademik': 'Akademik',
    'kehadiran': 'Kehadiran',
    'perilaku': 'Perilaku',
    'keuangan': 'Keuangan',
    'sosial': 'Sosial',
  };

  Color _categoryColor(String category) {
    switch (category) {
      case 'critical':
        return AppColors.error;
      case 'high':
        return Colors.deepOrange;
      case 'medium':
        return AppColors.warning;
      default:
        return AppColors.success;
    }
  }

  Color _scoreColor(int score) {
    if (score >= 75) return AppColors.error;
    if (score >= 55) return Colors.deepOrange;
    if (score >= 35) return AppColors.warning;
    return AppColors.success;
  }

  @override
  Widget build(BuildContext context) {
    final risk = insight.riskProfile;
    final pad = context.pagePadding;
    if (risk == null) {
      return Center(
        child: Text(
          'Profil risiko belum tersedia',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    final score = (risk['risk_score'] as num?)?.toInt() ?? 0;
    final category = risk['risk_category'] as String? ?? 'low';
    final recommendations =
        (risk['recommendations'] as List?)?.map((e) => e.toString()).toList() ??
        const [];
    final dimensions =
        (risk['dimensions'] as Map?)?.cast<String, dynamic>() ?? {};

    return ListView(
      padding: EdgeInsets.fromLTRB(pad.left, 12, pad.right, pad.bottom + 24),
      children: [
        Card(
          color: _categoryColor(category).withAlpha(30),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'Skor Risiko',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  '$score',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: _categoryColor(category),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Kategori: ${category.toUpperCase()}',
                  style: TextStyle(
                    color: _categoryColor(category),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text('Dimensi Risiko', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        ...dimensions.entries.map((e) {
          final label = _dimensionLabels[e.key] ?? e.key;
          final dim = e.value is Map
              ? (e.value as Map).cast<String, dynamic>()
              : <String, dynamic>{};
          final dimScore = (dim['score'] as num?)?.toInt() ?? 0;
          final issues =
              (dim['issues'] as List?)?.map((x) => x.toString()).toList() ?? [];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            label,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        Text(
                          '$dimScore',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: (dimScore / 100).clamp(0.0, 1.0),
                      backgroundColor: AppColors.divider,
                      color: _scoreColor(dimScore),
                    ),
                    if (issues.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      ...issues.map(
                        (s) => Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.fiber_manual_record, size: 8),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  s,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }),
        if (recommendations.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('Rekomendasi', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: recommendations
                    .map(
                      (r) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.lightbulb_outline,
                              size: 16,
                              color: AppColors.warning,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                r,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _AcademicTab extends StatelessWidget {
  final SiswaInsightEntity insight;

  const _AcademicTab({required this.insight});

  @override
  Widget build(BuildContext context) {
    final academic = insight.academicProgress;
    final pad = context.pagePadding;
    if (academic == null) {
      return Center(
        child: Text(
          'Data akademik belum tersedia',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    final rata = (academic['rata_rata_keseluruhan'] as num?)?.toDouble() ?? 0;
    final ranking = (academic['ranking_kelas'] as num?)?.toInt();
    final perMapel =
        (academic['per_mapel'] as Map?)?.cast<String, dynamic>() ?? {};
    final anomali = (academic['anomali'] as List?)?.cast<dynamic>() ?? [];

    return ListView(
      padding: EdgeInsets.fromLTRB(pad.left, 12, pad.right, pad.bottom + 24),
      children: [
        _ResponsiveRow(
          children: [
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rata-rata',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        rata.toStringAsFixed(1),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ranking Kelas',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ranking?.toString() ?? '-',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (perMapel.isNotEmpty) ...[
          Text(
            'Per Mata Pelajaran',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          ...perMapel.entries.map((e) {
            final v = e.value is Map
                ? (e.value as Map).cast<String, dynamic>()
                : <String, dynamic>{};
            final rataMapel = (v['rata_rata'] as num?)?.toDouble() ?? 0;
            final tren = v['tren'] as String? ?? 'stabil';
            final proyeksi = (v['proyeksi_akhir'] as num?)?.toDouble();
            return Card(
              child: ListTile(
                title: Text(e.key),
                subtitle: Text(
                  'Rata-rata: ${rataMapel.toStringAsFixed(1)}'
                  '${proyeksi != null ? ' · Proyeksi: ${proyeksi.toStringAsFixed(1)}' : ''}',
                ),
                trailing: _trenChip(tren),
              ),
            );
          }),
        ],
        if (anomali.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'Anomali Terdeteksi',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          ...anomali.map((a) {
            final v = a is Map
                ? a.cast<String, dynamic>()
                : <String, dynamic>{};
            return Card(
              color: AppColors.warning.withAlpha(30),
              child: ListTile(
                leading: const Icon(
                  Icons.error_outline,
                  color: AppColors.warning,
                ),
                title: Text(v['mapel']?.toString() ?? '-'),
                subtitle: Text(v['deskripsi']?.toString() ?? '-'),
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _trenChip(String tren) {
    Color color;
    switch (tren) {
      case 'naik':
        color = AppColors.success;
        break;
      case 'turun':
        color = AppColors.error;
        break;
      default:
        color = AppColors.textSecondary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(40),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        tren,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _AttendanceTab extends StatelessWidget {
  final SiswaInsightEntity insight;

  const _AttendanceTab({required this.insight});

  @override
  Widget build(BuildContext context) {
    final k = insight.kehadiranSummary;
    final pad = context.pagePadding;
    if (k == null) {
      return Center(
        child: Text(
          'Data kehadiran belum tersedia',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    final pct = (k['pct_hadir'] as num?)?.toDouble() ?? 0;
    final total = (k['total'] as num?)?.toInt() ?? 0;
    final hadir = (k['hadir'] as num?)?.toInt() ?? 0;
    final izin = (k['izin'] as num?)?.toInt() ?? 0;
    final sakit = (k['sakit'] as num?)?.toInt() ?? 0;
    final alpha = (k['alpha'] as num?)?.toInt() ?? 0;
    final status = k['status'] as String? ?? '-';

    return ListView(
      padding: EdgeInsets.fromLTRB(pad.left, 12, pad.right, pad.bottom + 24),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  '${pct.toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Status: $status',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: (pct / 100).clamp(0.0, 1.0),
                  backgroundColor: AppColors.divider,
                  color: AppColors.success,
                ),
                const SizedBox(height: 8),
                Text(
                  'Periode: ${k['periode'] ?? '-'}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _BreakdownRow(
          label: 'Hadir',
          value: hadir,
          total: total,
          color: AppColors.success,
        ),
        _BreakdownRow(
          label: 'Izin',
          value: izin,
          total: total,
          color: AppColors.info,
        ),
        _BreakdownRow(
          label: 'Sakit',
          value: sakit,
          total: total,
          color: AppColors.warning,
        ),
        _BreakdownRow(
          label: 'Alpha',
          value: alpha,
          total: total,
          color: AppColors.error,
        ),
      ],
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  final String label;
  final int value;
  final int total;
  final Color color;

  const _BreakdownRow({
    required this.label,
    required this.value,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : value / total;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(label)),
                  Text('$value'),
                ],
              ),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: pct,
                backgroundColor: AppColors.divider,
                color: color,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FinanceTab extends StatelessWidget {
  final SiswaInsightEntity insight;

  const _FinanceTab({required this.insight});

  @override
  Widget build(BuildContext context) {
    final s = insight.sppSummary;
    final pad = context.pagePadding;
    if (s == null) {
      return Center(
        child: Text(
          'Data keuangan belum tersedia',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    final tahun = s['tahun'];
    final bulanBerjalan = (s['bulan_berjalan'] as num?)?.toInt() ?? 0;
    final lunas = (s['lunas'] as num?)?.toInt() ?? 0;
    final tunggakan = (s['tunggakan'] as num?)?.toInt() ?? 0;
    final total = (s['total_dibayar'] as num?)?.toDouble() ?? 0;
    final status = s['status'] as String? ?? '-';

    return ListView(
      padding: EdgeInsets.fromLTRB(pad.left, 12, pad.right, pad.bottom + 24),
      children: [
        Card(
          color: AppColors.success.withAlpha(30),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'Status: ${status.toUpperCase()}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Tahun ajaran $tahun',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _ResponsiveRow(
          children: [
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lunas',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$lunas / $bulanBerjalan',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tunggakan',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$tunggakan',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: tunggakan > 0
                              ? AppColors.error
                              : AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Total Dibayar',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                Text(
                  'Rp ${total.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const _ErrorView({required this.message, this.onRetry});

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
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
