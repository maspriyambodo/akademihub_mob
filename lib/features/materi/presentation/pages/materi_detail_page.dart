import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/log_akses_materi_entity.dart';
import '../../domain/entities/materi_entity.dart';
import '../../domain/usecases/log_akses_materi_usecase.dart';
import '../bloc/materi_detail_bloc.dart';
import '../widgets/materi_widgets.dart';

/// Detail satu materi pembelajaran.
///
/// Halaman ini juga bertugas mencatat log akses siswa:
/// - `POST /akademik/log-akses-materi` saat halaman dibuka (`initState`)
/// - `PUT /akademik/log-akses-materi/{id}/durasi` saat halaman ditutup
///   (`dispose`), dengan durasi dari [Stopwatch].
///
/// Keduanya *fire-and-forget*: dibungkus try/catch, hasilnya diabaikan, dan
/// tidak pernah memunculkan error atau memblokir UI.
class MateriDetailPage extends StatelessWidget {
  final MateriEntity materi;
  final String role;
  final int? siswaId;
  final int? kelasId;

  const MateriDetailPage({
    super.key,
    required this.materi,
    required this.role,
    this.siswaId,
    this.kelasId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<MateriDetailBloc>(),
      child: _MateriDetailView(
        materi: materi,
        role: role,
        siswaId: siswaId,
        kelasId: kelasId,
      ),
    );
  }
}

class _MateriDetailView extends StatefulWidget {
  final MateriEntity materi;
  final String role;
  final int? siswaId;
  final int? kelasId;

  const _MateriDetailView({
    required this.materi,
    required this.role,
    this.siswaId,
    this.kelasId,
  });

  @override
  State<_MateriDetailView> createState() => _MateriDetailViewState();
}

class _MateriDetailViewState extends State<_MateriDetailView> {
  /// Menghitung lama siswa berada di halaman detail.
  final Stopwatch _stopwatch = Stopwatch();

  /// Future berisi id log yang dibuat POST; null bila pencatatan tidak berlaku.
  Future<int?>? _logIdFuture;

  late final CatatAksesMateriUseCase _catatAkses;
  late final UpdateDurasiBacaUseCase _updateDurasi;

  bool get _bolehLihatStatistik =>
      widget.role == 'guru' || widget.role == 'admin';

  /// Log hanya dicatat untuk siswa yang id siswa & kelasnya diketahui —
  /// backend mewajibkan `siswa_id` dan `kelas_id` (kolom NOT NULL).
  bool get _bolehCatatAkses =>
      widget.role == 'siswa' &&
      widget.siswaId != null &&
      widget.kelasId != null;

  @override
  void initState() {
    super.initState();
    _catatAkses = sl<CatatAksesMateriUseCase>();
    _updateDurasi = sl<UpdateDurasiBacaUseCase>();

    _stopwatch.start();
    if (_bolehCatatAkses) {
      _logIdFuture = _kirimCatatAkses();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<MateriDetailBloc>().add(
        MateriDetailLoadRequested(
          materiId: widget.materi.id,
          awal: widget.materi,
          denganStatistik: _bolehLihatStatistik,
        ),
      );
    });
  }

  @override
  void dispose() {
    _stopwatch.stop();
    _kirimDurasi(_stopwatch.elapsed.inSeconds);
    super.dispose();
  }

  // ── Pencatatan log akses (fire-and-forget) ─────────────────────────────────

  Future<int?> _kirimCatatAkses() async {
    try {
      final hasil = await _catatAkses(
        materiId: widget.materi.id,
        siswaId: widget.siswaId!,
        kelasId: widget.kelasId!,
      );
      if (hasil.isFailure) return null;
      final id = hasil.requireData.id;
      return id > 0 ? id : null;
    } catch (_) {
      // Sengaja diabaikan — pencatatan log tidak boleh mengganggu pengguna.
      return null;
    }
  }

  void _kirimDurasi(int durasiDetik) {
    final future = _logIdFuture;
    if (future == null || durasiDetik < 0) return;
    unawaited(_prosesKirimDurasi(future, durasiDetik));
  }

  Future<void> _prosesKirimDurasi(
    Future<int?> logIdFuture,
    int durasiDetik,
  ) async {
    try {
      // POST bisa saja belum selesai saat halaman ditutup; tunggu id-nya.
      final logId = await logIdFuture;
      if (logId == null) return;
      await _updateDurasi(logId: logId, durasiDetik: durasiDetik);
    } catch (_) {
      // Sengaja diabaikan.
    }
  }

  // ── Buka lampiran ──────────────────────────────────────────────────────────

  /// `file_materi` di backend hanya varchar(255) tanpa normalisasi, jadi bisa
  /// berupa URL penuh ATAU path relatif di storage. Bila relatif, URL disusun
  /// dari host base URL API + `/storage/...`.
  Uri? _bangunUri(String raw) {
    final bersih = raw.trim();
    if (bersih.isEmpty) return null;

    final uri = Uri.tryParse(bersih);
    if (uri != null &&
        uri.hasScheme &&
        (uri.isScheme('http') || uri.isScheme('https'))) {
      return uri;
    }

    final base = Uri.tryParse(AppConfig.apiBaseUrl);
    if (base == null) return null;

    final path = bersih.startsWith('/') ? bersih.substring(1) : bersih;
    final berawalanStorage =
        path.startsWith('storage/') || path.startsWith('public/');
    return base.replace(
      path: berawalanStorage ? '/$path' : '/storage/$path',
    );
  }

  Future<void> _bukaLampiran(String raw) async {
    final messenger = ScaffoldMessenger.of(context);
    final uri = _bangunUri(raw);

    if (uri == null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Lampiran tidak dapat dibuka: $raw'),
          backgroundColor: AppColors.info,
        ),
      );
      return;
    }

    var berhasil = false;
    try {
      berhasil = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      berhasil = false;
    }

    if (!berhasil) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Tidak dapat membuka lampiran'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Materi'), centerTitle: true),
      body: BlocBuilder<MateriDetailBloc, MateriDetailState>(
        builder: (context, state) {
          if (state is MateriDetailLoading || state is MateriDetailInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is MateriDetailError) {
            return _DetailErrorView(
              message: state.message,
              onRetry: () => context.read<MateriDetailBloc>().add(
                const MateriDetailRefreshRequested(),
              ),
            );
          }
          if (state is MateriDetailLoaded) {
            return RefreshIndicator(
              onRefresh: () async {
                context.read<MateriDetailBloc>().add(
                  const MateriDetailRefreshRequested(),
                );
              },
              child: _DetailBody(
                state: state,
                tampilkanStatistik: _bolehLihatStatistik,
                onBukaLampiran: _bukaLampiran,
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

// ── Isi detail ───────────────────────────────────────────────────────────────

class _DetailBody extends StatelessWidget {
  final MateriDetailLoaded state;
  final bool tampilkanStatistik;
  final Future<void> Function(String) onBukaLampiran;

  const _DetailBody({
    required this.state,
    required this.tampilkanStatistik,
    required this.onBukaLampiran,
  });

  @override
  Widget build(BuildContext context) {
    final m = state.materi;
    final warna = warnaMateri(m.tipe);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // ── Header ────────────────────────────────────────────────────────
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: warna.withAlpha(30),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(ikonMateri(m.tipe), size: 24, color: warna),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        m.judul,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _InfoRow(icon: Icons.menu_book_outlined, text: m.mapelLabel),
                _InfoRow(icon: Icons.person_outline, text: m.guruLabel),
                _InfoRow(
                  icon: Icons.schedule,
                  text: m.createdAtDate == null
                      ? 'Tanggal tidak diketahui'
                      : 'Diunggah ${formatTanggalWaktu(m.createdAtDate)}'
                            ' · ${waktuRelatif(m.createdAtDate)}',
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    MateriBadge(
                      label: m.tipe.label,
                      color: warna,
                      icon: ikonMateri(m.tipe),
                    ),
                    if (tampilkanStatistik)
                      MateriBadge(
                        label: m.statusLabel ?? (m.isAktif ? 'Aktif' : 'Draft'),
                        color: m.isAktif
                            ? AppColors.success
                            : AppColors.warning,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // ── Deskripsi ─────────────────────────────────────────────────────
        const SizedBox(height: 12),
        MateriSectionCard(
          title: 'Deskripsi',
          icon: Icons.notes_outlined,
          child: Text(
            (m.deskripsi == null || m.deskripsi!.trim().isEmpty)
                ? 'Tidak ada deskripsi untuk materi ini.'
                : m.deskripsi!.trim(),
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.6,
              color: AppColors.textPrimary,
            ),
          ),
        ),

        // ── Lampiran ──────────────────────────────────────────────────────
        const SizedBox(height: 12),
        MateriSectionCard(
          title: 'Lampiran',
          icon: Icons.attachment_outlined,
          child: m.punyaLampiran
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (m.punyaFile) ...[
                      _LampiranTile(
                        icon: Icons.description_outlined,
                        judul: m.ekstensiFile == null
                            ? 'Berkas materi'
                            : 'Berkas materi (${m.ekstensiFile!.toUpperCase()})',
                        nilai: m.fileMateri!,
                        warna: AppColors.primary,
                        onTap: () => onBukaLampiran(m.fileMateri!),
                      ),
                      if (m.punyaVideo) const SizedBox(height: 10),
                    ],
                    if (m.punyaVideo)
                      _LampiranTile(
                        icon: Icons.play_circle_outline,
                        judul: 'Video pembelajaran',
                        nilai: m.linkVideo!,
                        warna: AppColors.error,
                        onTap: () => onBukaLampiran(m.linkVideo!),
                      ),
                    const SizedBox(height: 14),
                    if (m.punyaFile)
                      ElevatedButton.icon(
                        onPressed: () => onBukaLampiran(m.fileMateri!),
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Buka Berkas Materi'),
                      ),
                    if (m.punyaFile && m.punyaVideo) const SizedBox(height: 8),
                    if (m.punyaVideo)
                      OutlinedButton.icon(
                        onPressed: () => onBukaLampiran(m.linkVideo!),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Tonton Video'),
                      ),
                  ],
                )
              : const Text(
                  'Materi ini tidak memiliki berkas atau video lampiran.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
        ),

        // ── Statistik pembaca (guru & admin) ──────────────────────────────
        if (tampilkanStatistik) ...[
          const SizedBox(height: 12),
          _StatistikCard(state: state),
        ],
      ],
    );
  }
}

// ── Statistik pembaca ────────────────────────────────────────────────────────

class _StatistikCard extends StatelessWidget {
  final MateriDetailLoaded state;
  const _StatistikCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final statistik = state.statistik;

    if (state.memuatStatistik && statistik == null) {
      return const MateriSectionCard(
        title: 'Statistik Pembaca',
        icon: Icons.insights_outlined,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ),
        ),
      );
    }

    if (statistik == null) {
      return MateriSectionCard(
        title: 'Statistik Pembaca',
        icon: Icons.insights_outlined,
        child: Text(
          state.statistikGagal
              ? 'Statistik pembaca belum dapat dimuat.'
              : 'Statistik pembaca tidak tersedia.',
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    if (statistik.kosong) {
      return const MateriSectionCard(
        title: 'Statistik Pembaca',
        icon: Icons.insights_outlined,
        child: Text(
          'Belum ada siswa yang membuka materi ini.',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
      );
    }

    return MateriSectionCard(
      title: 'Statistik Pembaca',
      icon: Icons.insights_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StatTile(
                label: 'Pembaca',
                value: '${statistik.pembacaUnik}',
                icon: Icons.groups_outlined,
                color: AppColors.primary,
              ),
              const SizedBox(width: 10),
              _StatTile(
                label: 'Dibuka',
                value: '${statistik.totalAkses}x',
                icon: Icons.visibility_outlined,
                color: AppColors.info,
              ),
              const SizedBox(width: 10),
              _StatTile(
                label: 'Rata-rata',
                value: formatDurasi(statistik.rataDurasiDetik),
                icon: Icons.timer_outlined,
                color: AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Total durasi baca ${formatDurasi(statistik.totalDurasiDetik)}'
            '${statistik.aksesTerakhir == null ? '' : ' · terakhir ${waktuRelatif(statistik.aksesTerakhir)}'}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          if (statistik.terbaru.isNotEmpty) ...[
            const Divider(height: 24),
            const Text(
              'Akses terbaru',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            ...statistik.terbaru.map(_barisLog),
          ],
        ],
      ),
    );
  }

  Widget _barisLog(LogAksesMateriEntity log) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          const Icon(
            Icons.person_outline,
            size: 15,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              log.siswaNama ?? 'Siswa #${log.siswaId ?? '-'}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Text(
            '${log.durasiLabel ?? formatDurasi(log.durasiDetik)} · '
            '${waktuRelatif(log.waktuAksesDate)}',
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

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10.5,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Widget kecil ─────────────────────────────────────────────────────────────

class _LampiranTile extends StatelessWidget {
  final IconData icon;
  final String judul;
  final String nilai;
  final Color warna;
  final VoidCallback onTap;

  const _LampiranTile({
    required this.icon,
    required this.judul,
    required this.nilai,
    required this.warna,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: warna),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    judul,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    nilai,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.open_in_new,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ],
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _DetailErrorView({required this.message, required this.onRetry});

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
