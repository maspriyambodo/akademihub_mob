import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:open_filex/open_filex.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/rapor_detail_entity.dart';
import '../../domain/entities/rapor_entity.dart';
import '../../domain/entities/rapor_mapel_entity.dart';
import '../bloc/rapor_detail_bloc.dart';

/// Halaman detail rapor.
///
/// [rapor] adalah item dari daftar; dipakai untuk melengkapi header karena
/// endpoint `/rapor/{id}/detail` TIDAK mengirim `kelas`, `rata_rata`,
/// maupun `ranking`.
class RaporDetailPage extends StatelessWidget {
  final RaporEntity rapor;
  final bool canExport;

  const RaporDetailPage({
    super.key,
    required this.rapor,
    required this.canExport,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          sl<RaporDetailBloc>()..add(RaporDetailLoadRequested(rapor.id)),
      child: _RaporDetailView(rapor: rapor, canExport: canExport),
    );
  }
}

class _RaporDetailView extends StatelessWidget {
  final RaporEntity rapor;
  final bool canExport;

  const _RaporDetailView({required this.rapor, required this.canExport});

  Future<void> _bukaBerkas(BuildContext context, String path) async {
    final result = await OpenFilex.open(path);
    if (!context.mounted) return;
    if (result.type != ResultType.done) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Berkas rapor tersimpan di:\n$path\n'
            'Tidak ada aplikasi yang bisa membuka berkas .xlsx di perangkat ini.',
          ),
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Rapor'), centerTitle: true),
      body: BlocConsumer<RaporDetailBloc, RaporDetailState>(
        listenWhen: (prev, curr) =>
            curr is RaporDetailLoaded &&
            (prev is! RaporDetailLoaded ||
                prev.exportStatus != curr.exportStatus),
        listener: (context, state) {
          if (state is! RaporDetailLoaded) return;

          if (state.exportStatus == RaporExportStatus.success &&
              state.exportPath != null) {
            _bukaBerkas(context, state.exportPath!);
          } else if (state.exportStatus == RaporExportStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.exportMessage ?? 'Gagal mengunduh berkas rapor',
                ),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is RaporDetailInitial || state is RaporDetailLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is RaporDetailError) {
            return _ErrorView(
              message: state.message,
              onRetry: () => context.read<RaporDetailBloc>().add(
                const RaporDetailRefreshRequested(),
              ),
            );
          }
          if (state is RaporDetailLoaded) {
            return _Content(
              rapor: rapor,
              state: state,
              canExport: canExport,
              onRefresh: () async {
                context.read<RaporDetailBloc>().add(
                  const RaporDetailRefreshRequested(),
                );
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

// ── Content ──────────────────────────────────────────────────────────────────

class _Content extends StatelessWidget {
  final RaporEntity rapor;
  final RaporDetailLoaded state;
  final bool canExport;
  final Future<void> Function() onRefresh;

  const _Content({
    required this.rapor,
    required this.state,
    required this.canExport,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final detail = state.detail;
    final siswaId = detail.siswaId ?? rapor.siswaId;
    final exporting = state.exportStatus == RaporExportStatus.loading;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _HeaderCard(rapor: rapor, detail: detail),
          const SizedBox(height: 16),

          // ── Nilai per mapel ────────────────────────────────────────────
          const _SectionTitle('Nilai per Mata Pelajaran'),
          const SizedBox(height: 8),
          if (detail.mapel.isEmpty)
            const _EmptyView(message: 'Belum ada rincian nilai mata pelajaran')
          else
            ...detail.mapel.map((m) => _MapelCard(mapel: m)),

          // ── Rekap kehadiran ────────────────────────────────────────────
          if (detail.punyaKehadiran) ...[
            const SizedBox(height: 20),
            const _SectionTitle('Rekap Kehadiran'),
            const SizedBox(height: 8),
            _KehadiranCard(detail: detail),
          ],

          // ── Catatan / narasi wali kelas ────────────────────────────────
          if (detail.punyaCatatan) ...[
            const SizedBox(height: 20),
            const _SectionTitle('Catatan Wali Kelas'),
            const SizedBox(height: 8),
            _CatatanCard(catatan: detail.catatanWali!),
          ],

          // ── Unduh rapor (hanya bila punya permission `rapor.export`) ───
          if (canExport && siswaId != null) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: exporting
                  ? null
                  : () => context.read<RaporDetailBloc>().add(
                      RaporDetailExportRequested(siswaId),
                    ),
              icon: exporting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.download_outlined),
              label: Text(exporting ? 'Menyiapkan berkas...' : 'Unduh Rapor'),
            ),
            const SizedBox(height: 8),
            const Text(
              'Berkas rapor diunduh dalam format Excel (.xlsx) lalu dibuka '
              'dengan aplikasi yang tersedia di perangkat Anda.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Header identitas ─────────────────────────────────────────────────────────

class _HeaderCard extends StatelessWidget {
  final RaporEntity rapor;
  final RaporDetailEntity detail;

  const _HeaderCard({required this.rapor, required this.detail});

  @override
  Widget build(BuildContext context) {
    final nama = detail.siswaNama ?? rapor.siswaNama ?? 'Siswa';
    final nis = detail.siswaNis ?? rapor.siswaNis;
    final kelas = rapor.kelas; // endpoint detail tidak mengirim kelas
    final semester = detail.semester ?? rapor.semester;
    final tahunAjaran = detail.tahunAjaran ?? rapor.tahunAjaran;
    final rata = rapor.rataRata ?? detail.rataRataHitung;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white.withAlpha(50),
                child: const Icon(
                  Icons.person_outline,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nama,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (nis != null && nis.isNotEmpty) 'NIS $nis',
                        if (kelas != null && kelas.isNotEmpty) kelas,
                      ].join('  ·  '),
                      style: TextStyle(
                        color: Colors.white.withAlpha(220),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              _HeaderStat(
                label: 'Semester',
                value: (semester != null && semester.isNotEmpty)
                    ? semester
                    : '-',
              ),
              _HeaderStat(
                label: 'Tahun Ajaran',
                value: (tahunAjaran != null && tahunAjaran.isNotEmpty)
                    ? tahunAjaran
                    : '-',
              ),
              _HeaderStat(
                label: 'Rata-rata',
                value: rata != null ? rata.toStringAsFixed(2) : '-',
              ),
              if (rapor.peringkat != null)
                _HeaderStat(
                  label: 'Peringkat',
                  value: '${rapor.peringkat}',
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final String label;
  final String value;

  const _HeaderStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 10),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Kartu mapel ──────────────────────────────────────────────────────────────

class _MapelCard extends StatelessWidget {
  final RaporMapelEntity mapel;
  const _MapelCard({required this.mapel});

  @override
  Widget build(BuildContext context) {
    final nilai = mapel.nilaiUtama;
    final color = _nilaiColor(nilai);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mapel.mapelNama ?? 'Mata Pelajaran',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (mapel.mapelKode != null &&
                          mapel.mapelKode!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          mapel.mapelKode!,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      nilai != null ? nilai.toStringAsFixed(2) : '-',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    if (mapel.predikat != null &&
                        mapel.predikat!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: color.withAlpha(25),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: color.withAlpha(70)),
                        ),
                        child: Text(
                          mapel.predikat!,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            if (mapel.punyaNilaiPengetahuan ||
                mapel.punyaNilaiKeterampilan) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  if (mapel.punyaNilaiPengetahuan)
                    _NilaiPill(
                      label: 'Pengetahuan',
                      value: mapel.nilaiPengetahuan!,
                    ),
                  if (mapel.punyaNilaiPengetahuan &&
                      mapel.punyaNilaiKeterampilan)
                    const SizedBox(width: 8),
                  if (mapel.punyaNilaiKeterampilan)
                    _NilaiPill(
                      label: 'Keterampilan',
                      value: mapel.nilaiKeterampilan!,
                    ),
                ],
              ),
            ],
            if (mapel.deskripsi != null && mapel.deskripsi!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                mapel.deskripsi!,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _nilaiColor(double? nilai) {
    if (nilai == null) return AppColors.textSecondary;
    if (nilai >= 90) return AppColors.success;
    if (nilai >= 75) return AppColors.info;
    if (nilai >= 60) return AppColors.warning;
    return AppColors.error;
  }
}

class _NilaiPill extends StatelessWidget {
  final String label;
  final double value;

  const _NilaiPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              value.toStringAsFixed(2),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Rekap kehadiran ──────────────────────────────────────────────────────────

class _KehadiranCard extends StatelessWidget {
  final RaporDetailEntity detail;
  const _KehadiranCard({required this.detail});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            _KehadiranItem(
              label: 'Sakit',
              value: detail.sakit ?? 0,
              color: AppColors.warning,
            ),
            _KehadiranItem(
              label: 'Izin',
              value: detail.izin ?? 0,
              color: AppColors.info,
            ),
            _KehadiranItem(
              label: 'Tanpa Ket.',
              value: detail.tanpaKeterangan ?? 0,
              color: AppColors.error,
            ),
          ],
        ),
      ),
    );
  }
}

class _KehadiranItem extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _KehadiranItem({
    required this.label,
    required this.value,
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
          border: Border.all(color: color.withAlpha(70)),
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: TextStyle(
                fontSize: 20,
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

// ── Catatan wali kelas ───────────────────────────────────────────────────────

class _CatatanCard extends StatelessWidget {
  final String catatan;
  const _CatatanCard({required this.catatan});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.format_quote,
              size: 20,
              color: AppColors.textHint,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                catatan,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section title ────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.menu_book_outlined,
              size: 56,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
