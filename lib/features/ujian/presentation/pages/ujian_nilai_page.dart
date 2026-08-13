import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../domain/entities/ujian_entity.dart';
import '../../domain/entities/ujian_nilai_entity.dart';
import '../bloc/ujian_nilai_bloc.dart';

/// Halaman daftar nilai satu ujian (`GET /akademik/ujian/{id}/nilai`).
/// Dibuka via `Navigator.push` dari [UjianPage]; hanya dapat diakses
/// pemegang permission `ujian.view` (route dijaga middleware backend).
class UjianNilaiPage extends StatelessWidget {
  final int ujianId;

  /// Judul sementara di AppBar selagi data dimuat.
  final String judulAwal;

  /// Id siswa login — barisnya disorot pada daftar nilai.
  final int? siswaId;

  const UjianNilaiPage({
    super.key,
    required this.ujianId,
    this.judulAwal = 'Nilai Ujian',
    this.siswaId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          sl<UjianNilaiBloc>()..add(UjianNilaiLoadRequested(ujianId)),
      child: _UjianNilaiView(judulAwal: judulAwal, siswaId: siswaId),
    );
  }
}

class _UjianNilaiView extends StatelessWidget {
  final String judulAwal;
  final int? siswaId;

  const _UjianNilaiView({required this.judulAwal, required this.siswaId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<UjianNilaiBloc, UjianNilaiState>(
          builder: (context, state) => Text(
            state is UjianNilaiLoaded
                ? (state.detail.ujian?.nama ?? judulAwal)
                : judulAwal,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<UjianNilaiBloc, UjianNilaiState>(
        builder: (context, state) {
          if (state is UjianNilaiInitial || state is UjianNilaiLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is UjianNilaiError) {
            return _ErrorView(
              message: state.message,
              onRetry: () => context.read<UjianNilaiBloc>().add(
                const UjianNilaiRefreshRequested(),
              ),
            );
          }
          if (state is! UjianNilaiLoaded) return const SizedBox.shrink();

          final detail = state.detail;
          final pad = Responsive.pagePadding(context);
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: Responsive.lebarKontenMaks(context),
              ),
              child: RefreshIndicator(
                onRefresh: () async => context.read<UjianNilaiBloc>().add(
                  const UjianNilaiRefreshRequested(),
                ),
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        pad.left,
                        pad.top,
                        pad.right,
                        24,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          if (detail.ujian != null)
                            _UjianInfoCard(ujian: detail.ujian!),
                          _RingkasanNilai(nilai: detail.nilai),
                          if (detail.nilai.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 48),
                              child: _EmptyView(
                                message:
                                    'Belum ada nilai yang diinput untuk ujian ini',
                              ),
                            )
                          else
                            ...detail.nilai.map(
                              (item) => _NilaiRow(
                                item: item,
                                milikSaya:
                                    siswaId != null && item.siswaId == siswaId,
                              ),
                            ),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Kartu info ujian ─────────────────────────────────────────────────────────

class _UjianInfoCard extends StatelessWidget {
  final UjianEntity ujian;
  const _UjianInfoCard({required this.ujian});

  static const _months = [
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

  String _tanggalLabel() {
    final d = ujian.tanggalDate;
    if (d == null) return ujian.tanggal ?? '-';
    return '${d.day} ${_months[d.month]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final rows = <(IconData, String, String)>[
      if (ujian.jenisLabel != null)
        (Icons.category_outlined, 'Jenis', ujian.jenisLabel!),
      if (ujian.mapelNama != null)
        (Icons.menu_book_outlined, 'Mapel', ujian.mapelNama!),
      if (ujian.kelasNama != null)
        (Icons.school_outlined, 'Kelas', ujian.kelasNama!),
      (Icons.event_outlined, 'Tanggal', _tanggalLabel()),
      if (ujian.semesterNama != null)
        (Icons.calendar_view_month_outlined, 'Semester', ujian.semesterNama!),
      if (ujian.tahunAjaran != null)
        (Icons.date_range_outlined, 'Tahun Ajaran', ujian.tahunAjaran!),
      if (ujian.keterangan != null && ujian.keterangan!.isNotEmpty)
        (Icons.notes_outlined, 'Keterangan', ujian.keterangan!),
    ];

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (icon, label, value) in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 90,
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        value,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Ringkasan nilai ──────────────────────────────────────────────────────────

class _RingkasanNilai extends StatelessWidget {
  final List<UjianNilaiEntity> nilai;
  const _RingkasanNilai({required this.nilai});

  @override
  Widget build(BuildContext context) {
    final values = nilai
        .map((n) => n.nilai)
        .whereType<double>()
        .toList(growable: false);
    final rataRata = values.isEmpty
        ? null
        : values.reduce((a, b) => a + b) / values.length;
    final tertinggi = values.isEmpty
        ? null
        : values.reduce((a, b) => a > b ? a : b);
    final terendah = values.isEmpty
        ? null
        : values.reduce((a, b) => a < b ? a : b);

    String fmt(double? v) => v == null ? '-' : v.toStringAsFixed(1);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withAlpha(60)),
      ),
      child: Row(
        children: [
          _StatItem(label: 'Siswa', value: '${nilai.length}'),
          _StatItem(label: 'Rata-rata', value: fmt(rataRata)),
          _StatItem(label: 'Tertinggi', value: fmt(tertinggi)),
          _StatItem(label: 'Terendah', value: fmt(terendah)),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Baris nilai siswa ────────────────────────────────────────────────────────

class _NilaiRow extends StatelessWidget {
  final UjianNilaiEntity item;
  final bool milikSaya;

  const _NilaiRow({required this.item, required this.milikSaya});

  Color _nilaiColor(double? nilai) {
    if (nilai == null) return AppColors.textSecondary;
    if (nilai >= 85) return AppColors.success;
    if (nilai >= 70) return AppColors.info;
    if (nilai >= 55) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final color = _nilaiColor(item.nilai);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: milikSaya ? AppColors.primary.withAlpha(18) : AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: milikSaya ? AppColors.primary : AppColors.divider,
          width: milikSaya ? 1.4 : 1,
        ),
      ),
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          backgroundColor: color.withAlpha(28),
          child: Text(
            item.nilai == null
                ? '-'
                : item.nilai!.toStringAsFixed(
                    item.nilai! == item.nilai!.roundToDouble() ? 0 : 1,
                  ),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                item.siswaNama ?? 'Siswa #${item.siswaId ?? '-'}',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: milikSaya ? FontWeight.w700 : FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (milikSaya) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Anda',
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(
          [
            if (item.siswaNis != null) 'NIS ${item.siswaNis}',
            if (item.keterangan != null && item.keterangan!.isNotEmpty)
              item.keterangan!,
          ].join(' · '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 11.5,
            color: AppColors.textSecondary,
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
              style: ElevatedButton.styleFrom(minimumSize: const Size(160, 44)),
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
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.grading_outlined,
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
