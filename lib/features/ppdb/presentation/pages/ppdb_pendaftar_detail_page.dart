import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/ppdb_dokumen_entity.dart';
import '../../domain/entities/ppdb_hasil_seleksi_entity.dart';
import '../../domain/entities/ppdb_pendaftar_entity.dart';
import '../bloc/ppdb_detail_bloc.dart';
import '../widgets/ppdb_visuals.dart';

/// Permission untuk data pelengkap & aksi tulis (grup `/ppdb` di
/// `routes/api.php`; role `admin` dan `admin_ppdb` memiliki semuanya,
/// `kepala_sekolah`/`wakil_kepala_sekolah` hanya `*.view`).
const String _permDokumenByPendaftar = 'ppdb.dokumen.by-pendaftaran';
const String _permSeleksiView = 'ppdb.seleksi.view';
const String _permDokumenVerify = 'ppdb.dokumen.verify';
const String _permDokumenReject = 'ppdb.dokumen.reject';
const String _permPendaftarVerify = 'ppdb.pendaftaran.verify';
const String _permPendaftarAccept = 'ppdb.pendaftaran.accept';
const String _permPendaftarReject = 'ppdb.pendaftaran.reject';

/// Halaman detail satu pendaftar PPDB: biodata, nilai rapor, dokumen
/// (+ verifikasi/tolak bila diizinkan), dan hasil seleksi bila ada.
class PpdbPendaftarDetailPage extends StatelessWidget {
  final int pendaftarId;
  final String? namaAwal;

  const PpdbPendaftarDetailPage({
    super.key,
    required this.pendaftarId,
    this.namaAwal,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<PpdbDetailBloc>(),
      child: _PpdbDetailView(pendaftarId: pendaftarId, namaAwal: namaAwal),
    );
  }
}

class _PpdbDetailView extends StatefulWidget {
  final int pendaftarId;
  final String? namaAwal;

  const _PpdbDetailView({required this.pendaftarId, this.namaAwal});

  @override
  State<_PpdbDetailView> createState() => _PpdbDetailViewState();
}

class _PpdbDetailViewState extends State<_PpdbDetailView> {
  bool _bolehVerifikasiDokumen = false;
  bool _bolehTolakDokumen = false;
  bool _bolehVerifikasiPendaftar = false;
  bool _bolehTerimaPendaftar = false;
  bool _bolehTolakPendaftar = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authState = context.read<AuthBloc>().state;

      var bolehDokumen = false;
      var bolehSeleksi = false;
      if (authState is AuthAuthenticated) {
        final user = authState.user;
        bolehDokumen = user.hasPermission(_permDokumenByPendaftar);
        bolehSeleksi = user.hasPermission(_permSeleksiView);
        setState(() {
          _bolehVerifikasiDokumen = user.hasPermission(_permDokumenVerify);
          _bolehTolakDokumen = user.hasPermission(_permDokumenReject);
          _bolehVerifikasiPendaftar = user.hasPermission(_permPendaftarVerify);
          _bolehTerimaPendaftar = user.hasPermission(_permPendaftarAccept);
          _bolehTolakPendaftar = user.hasPermission(_permPendaftarReject);
        });
      }

      context.read<PpdbDetailBloc>().add(
        PpdbDetailLoadRequested(
          pendaftarId: widget.pendaftarId,
          bolehLihatDokumen: bolehDokumen,
          bolehLihatSeleksi: bolehSeleksi,
        ),
      );
    });
  }

  // ── Dialog aksi ───────────────────────────────────────────────────────────

  Future<void> _dialogVerifikasiDokumen(PpdbDokumenEntity dokumen) async {
    final bloc = context.read<PpdbDetailBloc>();
    final controller = TextEditingController();
    final lanjut = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Verifikasi Dokumen', style: TextStyle(fontSize: 16)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tandai "${labelJenisDokumen(dokumen.jenisDokumen)}" sebagai '
                'terverifikasi?',
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Catatan (opsional)',
                  labelStyle: TextStyle(fontSize: 12.5),
                ),
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Verifikasi'),
          ),
        ],
      ),
    );
    if (lanjut == true) {
      bloc.add(
        PpdbDokumenVerifikasiDiminta(dokumen.id, catatan: controller.text),
      );
    }
    controller.dispose();
  }

  Future<void> _dialogTolakDokumen(PpdbDokumenEntity dokumen) async {
    final bloc = context.read<PpdbDetailBloc>();
    final controller = TextEditingController();
    final lanjut = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Tolak Dokumen', style: TextStyle(fontSize: 16)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tolak "${labelJenisDokumen(dokumen.jenisDokumen)}"? '
                'Alasan wajib diisi.',
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Alasan penolakan',
                  labelStyle: TextStyle(fontSize: 12.5),
                ),
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          ListenableBuilder(
            listenable: controller,
            builder: (_, _) => FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: controller.text.trim().isEmpty
                  ? null
                  : () => Navigator.of(dialogContext).pop(true),
              child: const Text('Tolak'),
            ),
          ),
        ],
      ),
    );
    if (lanjut == true && controller.text.trim().isNotEmpty) {
      bloc.add(
        PpdbDokumenTolakDiminta(dokumen.id, catatan: controller.text.trim()),
      );
    }
    controller.dispose();
  }

  Future<void> _konfirmasiAksiPendaftar(String aksi) async {
    final bloc = context.read<PpdbDetailBloc>();
    final (judul, pesan) = switch (aksi) {
      'verify' => (
        'Verifikasi Pendaftar',
        'Ubah status pendaftar menjadi "Terverifikasi"?',
      ),
      'accept' => (
        'Terima Pendaftar',
        'Nyatakan pendaftar ini DITERIMA? Status akan menjadi "Diterima".',
      ),
      _ => (
        'Tolak Pendaftar',
        'Nyatakan pendaftar ini DITOLAK? Status akan menjadi "Ditolak".',
      ),
    };

    final lanjut = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(judul, style: const TextStyle(fontSize: 16)),
        content: Text(pesan, style: const TextStyle(fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: aksi == 'reject'
                ? FilledButton.styleFrom(backgroundColor: AppColors.error)
                : null,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Ya, Lanjutkan'),
          ),
        ],
      ),
    );
    if (lanjut == true) {
      bloc.add(PpdbPendaftarAksiDiminta(aksi));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.namaAwal ?? 'Detail Pendaftar'),
        centerTitle: true,
      ),
      body: BlocConsumer<PpdbDetailBloc, PpdbDetailState>(
        listenWhen: (prev, curr) =>
            curr is PpdbDetailLoaded &&
            curr.notifikasi != null &&
            (prev is! PpdbDetailLoaded || prev.versi != curr.versi),
        listener: (context, state) {
          final loaded = state as PpdbDetailLoaded;
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(loaded.notifikasi!),
                backgroundColor: loaded.notifikasiSukses
                    ? AppColors.success
                    : AppColors.error,
              ),
            );
        },
        builder: (context, state) {
          if (state is PpdbDetailError) {
            // Refresh memakai izin yang sudah tersimpan di bloc dari load awal.
            return _ErrorView(
              message: state.message,
              onRetry: () => context.read<PpdbDetailBloc>().add(
                const PpdbDetailRefreshRequested(),
              ),
            );
          }
          if (state is! PpdbDetailLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          final pendaftar = state.pendaftar;
          return RefreshIndicator(
            onRefresh: () async {
              context.read<PpdbDetailBloc>().add(
                const PpdbDetailRefreshRequested(),
              );
            },
            child: Stack(
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: Responsive.lebarKontenMaks(context),
                    ),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: Responsive.pagePadding(
                        context,
                      ).add(const EdgeInsets.only(bottom: 12)),
                      children: [
                        _HeaderCard(pendaftar: pendaftar),
                        if (_adaAksiPendaftar(pendaftar)) ...[
                          const SizedBox(height: 10),
                          _AksiStatusCard(
                            pendaftar: pendaftar,
                            sedangProses: state.sedangProses,
                            bolehVerify: _bolehVerifikasiPendaftar,
                            bolehAccept: _bolehTerimaPendaftar,
                            bolehReject: _bolehTolakPendaftar,
                            onAksi: _konfirmasiAksiPendaftar,
                          ),
                        ],
                        const SizedBox(height: 10),
                        _BiodataCard(pendaftar: pendaftar),
                        const SizedBox(height: 10),
                        _NilaiRaporCard(state: state),
                        const SizedBox(height: 10),
                        _DokumenCard(
                          state: state,
                          bolehVerify: _bolehVerifikasiDokumen,
                          bolehReject: _bolehTolakDokumen,
                          onVerifikasi: _dialogVerifikasiDokumen,
                          onTolak: _dialogTolakDokumen,
                        ),
                        if (state.hasilSeleksi != null) ...[
                          const SizedBox(height: 10),
                          _HasilSeleksiCard(hasil: state.hasilSeleksi!),
                        ],
                      ],
                    ),
                  ),
                ),
                if (state.sedangProses)
                  Container(
                    color: Colors.black.withAlpha(40),
                    alignment: Alignment.center,
                    child: const CircularProgressIndicator(),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  bool _adaAksiPendaftar(PpdbPendaftarEntity pendaftar) {
    final status = pendaftar.statusPendaftaran;
    return (_bolehVerifikasiPendaftar && status == 'draft') ||
        (_bolehTerimaPendaftar && status != 'diterima') ||
        (_bolehTolakPendaftar && status != 'ditolak');
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _HeaderCard extends StatelessWidget {
  final PpdbPendaftarEntity pendaftar;

  const _HeaderCard({required this.pendaftar});

  @override
  Widget build(BuildContext context) {
    final warna = warnaStatusPendaftaran(pendaftar.statusPendaftaran);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: warna.withAlpha(26),
                  child: Icon(
                    pendaftar.jenisKelamin == 2
                        ? Icons.face_3_outlined
                        : Icons.face_outlined,
                    size: 26,
                    color: warna,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pendaftar.namaLengkap,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        pendaftar.noPendaftaran.isEmpty
                            ? '(tanpa nomor pendaftaran)'
                            : pendaftar.noPendaftaran,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      PpdbStatusChip(
                        label: labelStatusPendaftaran(
                          pendaftar.statusPendaftaran,
                        ),
                        warna: warna,
                        ikon: ikonStatusPendaftaran(
                          pendaftar.statusPendaftaran,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (pendaftar.namaGelombang != null ||
                pendaftar.namaSekolah != null) ...[
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 8),
              if (pendaftar.namaGelombang != null)
                _BarisIkon(
                  ikon: Icons.campaign_outlined,
                  teks: pendaftar.namaGelombang!,
                ),
              if (pendaftar.namaSekolah != null)
                _BarisIkon(
                  ikon: Icons.account_balance_outlined,
                  teks: pendaftar.namaSekolah!,
                ),
            ],
            if (pendaftar.isSuspectFraud) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.error.withAlpha(18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.warning_amber_outlined,
                      size: 15,
                      color: AppColors.error,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Terindikasi kecurangan'
                        '${pendaftar.fraudReason == null ? '' : ': ${pendaftar.fraudReason}'}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BarisIkon extends StatelessWidget {
  final IconData ikon;
  final String teks;

  const _BarisIkon({required this.ikon, required this.teks});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(ikon, size: 13, color: AppColors.textHint),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              teks,
              maxLines: 1,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Aksi status pendaftar ─────────────────────────────────────────────────────

class _AksiStatusCard extends StatelessWidget {
  final PpdbPendaftarEntity pendaftar;
  final bool sedangProses;
  final bool bolehVerify;
  final bool bolehAccept;
  final bool bolehReject;
  final ValueChanged<String> onAksi;

  const _AksiStatusCard({
    required this.pendaftar,
    required this.sedangProses,
    required this.bolehVerify,
    required this.bolehAccept,
    required this.bolehReject,
    required this.onAksi,
  });

  @override
  Widget build(BuildContext context) {
    final status = pendaftar.statusPendaftaran;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _JudulSeksi(
              ikon: Icons.gavel_outlined,
              teks: 'Aksi Status Pendaftaran',
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (bolehVerify && status == 'draft')
                  _TombolAksi(
                    label: 'Verifikasi',
                    ikon: Icons.verified_outlined,
                    warna: AppColors.info,
                    onTap: sedangProses ? null : () => onAksi('verify'),
                  ),
                if (bolehAccept && status != 'diterima')
                  _TombolAksi(
                    label: 'Terima',
                    ikon: Icons.check_circle_outline,
                    warna: AppColors.success,
                    onTap: sedangProses ? null : () => onAksi('accept'),
                  ),
                if (bolehReject && status != 'ditolak')
                  _TombolAksi(
                    label: 'Tolak',
                    ikon: Icons.cancel_outlined,
                    warna: AppColors.error,
                    onTap: sedangProses ? null : () => onAksi('reject'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TombolAksi extends StatelessWidget {
  final String label;
  final IconData ikon;
  final Color warna;
  final VoidCallback? onTap;

  const _TombolAksi({
    required this.label,
    required this.ikon,
    required this.warna,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(ikon, size: 16, color: warna),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: warna,
        ),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: warna.withAlpha(140)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}

// ── Biodata ───────────────────────────────────────────────────────────────────

class _BiodataCard extends StatelessWidget {
  final PpdbPendaftarEntity pendaftar;

  const _BiodataCard({required this.pendaftar});

  @override
  Widget build(BuildContext context) {
    final lahir = pendaftar.tanggalLahir == null
        ? null
        : '${formatTanggalPpdb(pendaftar.tanggalLahir)}'
              '${pendaftar.usia == null ? '' : ' (${pendaftar.usia} tahun)'}';

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _JudulSeksi(ikon: Icons.person_outline, teks: 'Biodata'),
            const SizedBox(height: 8),
            _BarisData('NISN', pendaftar.nisn),
            _BarisData('Jenis Kelamin', pendaftar.jenisKelaminLabel),
            _BarisData('Tanggal Lahir', lahir),
            _BarisData('No. HP', pendaftar.telpHp),
            _BarisData('Email', pendaftar.email),
            _BarisData('Asal Sekolah', pendaftar.asalSekolah),
            _BarisData('Jumlah Prestasi', pendaftar.jumlahPrestasi?.toString()),
            _BarisData(
              'Prestasi Tertinggi',
              pendaftar.tingkatPrestasiTertinggi,
            ),
            _BarisData(
              'Poin Pelanggaran',
              pendaftar.poinPelanggaran?.toString(),
            ),
            if (pendaftar.isHafidz)
              _BarisData('Hafidz', '${pendaftar.juzHafalan ?? 0} juz'),
            _BarisData(
              'Tanggal Daftar',
              pendaftar.createdAt == null
                  ? null
                  : formatTanggalPpdb(pendaftar.createdAt),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarisData extends StatelessWidget {
  final String label;
  final String? nilai;

  const _BarisData(this.label, this.nilai);

  @override
  Widget build(BuildContext context) {
    if (nilai == null || nilai!.isEmpty || nilai == '-') {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 128,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              nilai!,
              maxLines: 2,
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
    );
  }
}

// ── Nilai rapor ───────────────────────────────────────────────────────────────

class _NilaiRaporCard extends StatelessWidget {
  final PpdbDetailLoaded state;

  const _NilaiRaporCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final rataRata =
        state.nilaiStatistik.rataRata ?? state.pendaftar.nilaiRataRata;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: _JudulSeksi(
                    ikon: Icons.menu_book_outlined,
                    teks: 'Nilai Rapor',
                  ),
                ),
                if (rataRata != null)
                  PpdbStatusChip(
                    label: 'Rata-rata ${formatNilai(rataRata)}',
                    warna: AppColors.primary,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (state.nilaiList.isEmpty)
              const Text(
                'Belum ada nilai rapor yang diinput.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              )
            else ...[
              for (final n in state.nilaiList)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          n.labelMapel,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        formatNilai(n.nilai),
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              if (state.nilaiStatistik.jumlahMapel > 0) ...[
                const SizedBox(height: 6),
                const Divider(height: 1),
                const SizedBox(height: 6),
                Text(
                  '${state.nilaiStatistik.jumlahMapel} mapel · '
                  'tertinggi ${formatNilai(state.nilaiStatistik.nilaiTertinggi)} · '
                  'terendah ${formatNilai(state.nilaiStatistik.nilaiTerendah)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

// ── Dokumen ───────────────────────────────────────────────────────────────────

class _DokumenCard extends StatelessWidget {
  final PpdbDetailLoaded state;
  final bool bolehVerify;
  final bool bolehReject;
  final ValueChanged<PpdbDokumenEntity> onVerifikasi;
  final ValueChanged<PpdbDokumenEntity> onTolak;

  const _DokumenCard({
    required this.state,
    required this.bolehVerify,
    required this.bolehReject,
    required this.onVerifikasi,
    required this.onTolak,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _JudulSeksi(
              ikon: Icons.folder_open_outlined,
              teks: 'Dokumen (${state.dokumenList.length})',
            ),
            const SizedBox(height: 8),
            if (state.dokumenList.isEmpty)
              const Text(
                'Belum ada dokumen yang diunggah.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              )
            else
              for (final d in state.dokumenList)
                _DokumenTile(
                  dokumen: d,
                  bolehVerify: bolehVerify && !d.verifikasiStatus,
                  bolehReject: bolehReject,
                  sedangProses: state.sedangProses,
                  onVerifikasi: () => onVerifikasi(d),
                  onTolak: () => onTolak(d),
                ),
            if (!state.dokumenLengkap && state.dokumenList.isNotEmpty) ...[
              const SizedBox(height: 6),
              const Text(
                'Catatan admin dokumen tidak ditampilkan karena akun Anda '
                'tidak memiliki izin "ppdb.dokumen.by-pendaftaran".',
                style: TextStyle(fontSize: 10.5, color: AppColors.textHint),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DokumenTile extends StatelessWidget {
  final PpdbDokumenEntity dokumen;
  final bool bolehVerify;
  final bool bolehReject;
  final bool sedangProses;
  final VoidCallback onVerifikasi;
  final VoidCallback onTolak;

  const _DokumenTile({
    required this.dokumen,
    required this.bolehVerify,
    required this.bolehReject,
    required this.sedangProses,
    required this.onVerifikasi,
    required this.onTolak,
  });

  @override
  Widget build(BuildContext context) {
    final warna = dokumen.verifikasiStatus
        ? AppColors.success
        : AppColors.warning;
    final ukuran = formatUkuranFile(dokumen.fileSize);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                ikonJenisDokumen(dokumen.jenisDokumen),
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      labelJenisDokumen(dokumen.jenisDokumen),
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (dokumen.fileName.isNotEmpty)
                      Text(
                        ukuran.isEmpty
                            ? dokumen.fileName
                            : '${dokumen.fileName} · $ukuran',
                        maxLines: 1,
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              PpdbStatusChip(
                label: dokumen.verifikasiStatus
                    ? 'Terverifikasi'
                    : 'Belum Diverifikasi',
                warna: warna,
                ikon: dokumen.verifikasiStatus
                    ? Icons.verified_outlined
                    : Icons.schedule_outlined,
              ),
            ],
          ),
          if (dokumen.catatanAdmin != null &&
              dokumen.catatanAdmin!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Catatan: ${dokumen.catatanAdmin}',
              style: const TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          if (bolehVerify || bolehReject) ...[
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 4,
              runSpacing: 4,
              children: [
                if (bolehVerify)
                  TextButton.icon(
                    onPressed: sedangProses ? null : onVerifikasi,
                    icon: const Icon(
                      Icons.check,
                      size: 15,
                      color: AppColors.success,
                    ),
                    label: const Text(
                      'Verifikasi',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (bolehReject)
                  TextButton.icon(
                    onPressed: sedangProses ? null : onTolak,
                    icon: const Icon(
                      Icons.close,
                      size: 15,
                      color: AppColors.error,
                    ),
                    label: const Text(
                      'Tolak',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Hasil seleksi ─────────────────────────────────────────────────────────────

class _HasilSeleksiCard extends StatelessWidget {
  final PpdbHasilSeleksiEntity hasil;

  const _HasilSeleksiCard({required this.hasil});

  @override
  Widget build(BuildContext context) {
    final warna = warnaStatusSeleksi(hasil.statusSeleksi);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: _JudulSeksi(
                    ikon: Icons.emoji_events_outlined,
                    teks: 'Hasil Seleksi',
                  ),
                ),
                PpdbStatusChip(
                  label:
                      hasil.statusSeleksiLabel ??
                      labelStatusSeleksi(hasil.statusSeleksi),
                  warna: warna,
                ),
              ],
            ),
            const SizedBox(height: 8),
            _BarisData('Total Skor', formatNilai(hasil.totalSkor)),
            _BarisData(
              'Peringkat',
              hasil.peringkat == null ? null : '#${hasil.peringkat}',
            ),
            _BarisData(
              'Peringkat Jurusan',
              hasil.peringkatJurusan == null
                  ? null
                  : '#${hasil.peringkatJurusan}',
            ),
            _BarisData('Jurusan', hasil.namaJurusan),
            _BarisData(
              'Status Finalisasi',
              hasil.isFinalized ? 'Sudah difinalisasi' : 'Belum final',
            ),
            _BarisData('Catatan', hasil.catatanSeleksi),
          ],
        ),
      ),
    );
  }
}

// ── Judul seksi ───────────────────────────────────────────────────────────────

class _JudulSeksi extends StatelessWidget {
  final IconData ikon;
  final String teks;

  const _JudulSeksi({required this.ikon, required this.teks});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(ikon, size: 16, color: AppColors.primary),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            teks,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Error ─────────────────────────────────────────────────────────────────────

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
