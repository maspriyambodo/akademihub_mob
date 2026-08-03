import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../domain/entities/ekstrakurikuler_entity.dart';
import '../../domain/entities/ekstrakurikuler_statistik_entity.dart';
import '../bloc/ekstrakurikuler_bloc.dart';
import '../bloc/ekstrakurikuler_detail_bloc.dart';
import '../widgets/ekstrakurikuler_widgets.dart';

/// Halaman detail satu ekstrakurikuler.
///
/// Dibuka dengan `Navigator.push` dari `EkstrakurikulerPage`.
/// `EkstrakurikulerBloc` milik halaman utama ikut diteruskan
/// (`BlocProvider.value`) supaya aksi **Daftar** memakai bloc yang sama dan
/// daftar otomatis ter-refresh.
class EkstrakurikulerDetailPage extends StatelessWidget {
  final int ekstrakurikulerId;
  final String namaAwal;

  /// `profile['id']` bila role siswa — dipakai `check-status` & tombol Daftar.
  final int? siswaId;

  final bool canViewPendaftaran;
  final bool bolehMendaftar;
  final bool sudahTerdaftarDariDaftar;

  const EkstrakurikulerDetailPage({
    super.key,
    required this.ekstrakurikulerId,
    required this.namaAwal,
    this.siswaId,
    this.canViewPendaftaran = false,
    this.bolehMendaftar = false,
    this.sudahTerdaftarDariDaftar = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<EkstrakurikulerDetailBloc>()
        ..add(
          EkstrakurikulerDetailLoadRequested(
            ekstrakurikulerId: ekstrakurikulerId,
            siswaId: siswaId,
            canViewPendaftaran: canViewPendaftaran,
            sudahTerdaftarDariDaftar: sudahTerdaftarDariDaftar,
          ),
        ),
      child: _DetailView(
        ekstrakurikulerId: ekstrakurikulerId,
        namaAwal: namaAwal,
        bolehMendaftar: bolehMendaftar,
      ),
    );
  }
}

class _DetailView extends StatelessWidget {
  final int ekstrakurikulerId;
  final String namaAwal;
  final bool bolehMendaftar;

  const _DetailView({
    required this.ekstrakurikulerId,
    required this.namaAwal,
    required this.bolehMendaftar,
  });

  @override
  Widget build(BuildContext context) {
    // Setelah aksi daftar/keluar berhasil di bloc utama, muat ulang detail
    // agar statistik & status pendaftaran ikut diperbarui. SnackBar sengaja
    // tidak ditampilkan di sini — halaman utama yang menanganinya.
    return BlocListener<EkstrakurikulerBloc, EkstrakurikulerState>(
      listenWhen: (_, current) => current is EkstrakurikulerActionSuccess,
      listener: (context, _) => context.read<EkstrakurikulerDetailBloc>().add(
        const EkstrakurikulerDetailRefreshRequested(),
      ),
      child: Scaffold(
        appBar: AppBar(title: Text(namaAwal), centerTitle: true),
        body:
            BlocBuilder<EkstrakurikulerDetailBloc, EkstrakurikulerDetailState>(
              builder: (context, state) {
                if (state is EkstrakurikulerDetailInitial ||
                    state is EkstrakurikulerDetailLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is EkstrakurikulerDetailError) {
                  return _ErrorView(
                    message: state.message,
                    onRetry: () => context
                        .read<EkstrakurikulerDetailBloc>()
                        .add(const EkstrakurikulerDetailRefreshRequested()),
                  );
                }
                if (state is EkstrakurikulerDetailLoaded) {
                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<EkstrakurikulerDetailBloc>().add(
                        const EkstrakurikulerDetailRefreshRequested(),
                      );
                    },
                    child: BatasLebarKonten(
                      child: _KontenDetail(
                        state: state,
                        bolehMendaftar: bolehMendaftar,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
      ),
    );
  }
}

class _KontenDetail extends StatelessWidget {
  final EkstrakurikulerDetailLoaded state;
  final bool bolehMendaftar;

  const _KontenDetail({required this.state, required this.bolehMendaftar});

  @override
  Widget build(BuildContext context) {
    final ekskul = state.ekstrakurikuler;
    final tampilkanTombolDaftar =
        bolehMendaftar && !state.sudahTerdaftar && ekskul.isAktif;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        _HeaderDetail(ekskul: ekskul),

        if (state.sudahTerdaftar)
          const CatatanBanner(
            message: 'Anda sudah terdaftar pada ekstrakurikuler ini.',
            icon: Icons.verified_outlined,
            color: AppColors.success,
          ),

        if (tampilkanTombolDaftar)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.read<EkstrakurikulerBloc>().add(
                  EkstrakurikulerDaftarRequested(ekskul.id),
                ),
                icon: const Icon(Icons.how_to_reg),
                label: const Text(
                  'Daftar Ekstrakurikuler',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),

        _KartuSeksi(
          judul: 'Informasi',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InfoBaris(
                icon: Icons.person_outline,
                text: ekskul.hasPembina
                    ? 'Pembina: ${ekskul.pembinaNama}'
                          '${ekskul.pembinaNip != null ? ' (${ekskul.pembinaNip})' : ''}'
                    : 'Pembina belum ditentukan',
              ),
              InfoBaris(
                icon: Icons.event_outlined,
                text: 'Jadwal: ${ekskul.jadwalLabel}',
              ),
              InfoBaris(
                icon: Icons.place_outlined,
                text: 'Lokasi: ${ekskul.lokasi ?? '-'}',
              ),
              InfoBaris(icon: Icons.tag, text: 'Kode: ${ekskul.kode ?? '-'}'),
            ],
          ),
        ),

        _KartuSeksi(
          judul: 'Deskripsi',
          child: Text(
            (ekskul.deskripsi != null && ekskul.deskripsi!.trim().isNotEmpty)
                ? ekskul.deskripsi!
                : 'Belum ada deskripsi.',
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
        ),

        _KartuSeksi(
          judul: 'Statistik Peserta',
          child: _Statistik(statistik: state.statistik),
        ),

        if (state.dapatMelihatPeserta)
          _KartuSeksi(
            judul: 'Daftar Peserta (${state.peserta.length})',
            child: _DaftarPeserta(state: state),
          ),
      ],
    );
  }
}

// ── Header ───────────────────────────────────────────────────────────────────

class _HeaderDetail extends StatelessWidget {
  final EkstrakurikulerEntity ekskul;
  const _HeaderDetail({required this.ekskul});

  @override
  Widget build(BuildContext context) {
    final warna = warnaEkskul(ekskul.nama);

    final pad = Responsive.pagePadding(context);

    return Container(
      width: double.infinity,
      color: AppColors.cardBg,
      padding: EdgeInsets.fromLTRB(pad.left, 16, pad.right, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: warna.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.sports_soccer, color: warna, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ekskul.nama,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: Responsive.fontSize(context, 17),
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    StatusBadge(
                      label: ekskul.statusLabel,
                      color: ekskul.isAktif
                          ? AppColors.success
                          : AppColors.error,
                    ),
                    if (ekskul.hari != null && ekskul.hari!.isNotEmpty)
                      StatusBadge(
                        label: ekskul.hari!,
                        color: AppColors.primary,
                      ),
                    if (ekskul.jamLabel != null)
                      StatusBadge(
                        label: ekskul.jamLabel!,
                        color: AppColors.info,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Kartu seksi generik ──────────────────────────────────────────────────────

class _KartuSeksi extends StatelessWidget {
  final String judul;
  final Widget child;

  const _KartuSeksi({required this.judul, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              judul,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

// ── Statistik ────────────────────────────────────────────────────────────────

class _Statistik extends StatelessWidget {
  final EkstrakurikulerStatistikEntity? statistik;
  const _Statistik({required this.statistik});

  @override
  Widget build(BuildContext context) {
    final s = statistik;
    if (s == null) {
      return const Text(
        'Statistik tidak tersedia.',
        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            StatistikTile(
              label: 'Total',
              nilai: s.totalSiswa,
              color: AppColors.primary,
            ),
            const SizedBox(width: 8),
            StatistikTile(
              label: 'Aktif',
              nilai: s.totalSiswaAktif,
              color: AppColors.success,
            ),
            const SizedBox(width: 8),
            StatistikTile(
              label: 'Keluar',
              nilai: s.totalSiswaKeluar,
              color: AppColors.textSecondary,
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Tabel ekstrakurikuler tidak menyimpan kuota/daya tampung, sehingga '
          'tidak ada angka "terisi dari total kuota".',
          style: TextStyle(fontSize: 11, color: AppColors.textHint),
        ),
      ],
    );
  }
}

// ── Daftar peserta ───────────────────────────────────────────────────────────

class _DaftarPeserta extends StatelessWidget {
  final EkstrakurikulerDetailLoaded state;
  const _DaftarPeserta({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.pesanPeserta != null) {
      return Text(
        state.pesanPeserta!,
        style: const TextStyle(fontSize: 13, color: AppColors.error),
      );
    }
    if (state.peserta.isEmpty) {
      return const Text(
        'Belum ada peserta aktif.',
        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
      );
    }

    return Column(
      children: [
        for (final peserta in state.peserta)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 15,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  child: const Icon(
                    Icons.person,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        peserta.siswaNama ?? 'Siswa #${peserta.siswaId ?? '-'}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${peserta.siswaNis ?? '-'} · '
                        'gabung ${formatTanggalIndo(peserta.tanggalDaftar)}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                StatusBadge(
                  label: peserta.statusLabel,
                  color: peserta.isAktif
                      ? AppColors.success
                      : AppColors.textSecondary,
                ),
              ],
            ),
          ),
      ],
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
