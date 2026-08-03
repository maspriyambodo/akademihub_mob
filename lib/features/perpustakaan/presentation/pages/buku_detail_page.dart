import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../domain/entities/buku_entity.dart';
import '../../domain/entities/buku_riwayat_entity.dart';
import '../bloc/buku_detail_bloc.dart';
import '../bloc/perpustakaan_bloc.dart';
import '../widgets/perpustakaan_format.dart';
import '../widgets/perpustakaan_widgets.dart';
import '../widgets/pinjam_buku_sheet.dart';

/// Halaman detail satu buku.
///
/// Dibuka dengan `Navigator.push` dari [PerpustakaanPage] dan menerima
/// `PerpustakaanBloc` lewat `BlocProvider.value` supaya aksi "Pinjam Buku"
/// langsung menyegarkan katalog & daftar peminjaman di halaman utama.
class BukuDetailPage extends StatelessWidget {
  final int bukuId;
  final String judulAwal;

  /// Riwayat peminjaman buku hanya ditarik bila pengguna punya
  /// permission `peminjaman.view`.
  final bool canLihatRiwayat;

  /// Tombol "Pinjam Buku" hanya tampil bila punya `peminjaman.create`.
  final bool canPinjam;

  final int? defaultSiswaId;
  final bool kunciSiswa;

  const BukuDetailPage({
    super.key,
    required this.bukuId,
    required this.judulAwal,
    this.canLihatRiwayat = false,
    this.canPinjam = false,
    this.defaultSiswaId,
    this.kunciSiswa = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<BukuDetailBloc>()
        ..add(BukuDetailLoadRequested(bukuId, withRiwayat: canLihatRiwayat)),
      child: _BukuDetailView(
        judulAwal: judulAwal,
        canPinjam: canPinjam,
        defaultSiswaId: defaultSiswaId,
        kunciSiswa: kunciSiswa,
      ),
    );
  }
}

class _BukuDetailView extends StatelessWidget {
  final String judulAwal;
  final bool canPinjam;
  final int? defaultSiswaId;
  final bool kunciSiswa;

  const _BukuDetailView({
    required this.judulAwal,
    required this.canPinjam,
    this.defaultSiswaId,
    required this.kunciSiswa,
  });

  Future<void> _pinjam(BuildContext context, BukuEntity buku) async {
    final perpustakaanBloc = context.read<PerpustakaanBloc>();

    final hasil = await tampilkanFormPinjam(
      context,
      buku: buku,
      defaultSiswaId: defaultSiswaId,
      kunciSiswa: kunciSiswa,
    );
    if (hasil == null || !context.mounted) return;

    final setuju = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Konfirmasi Peminjaman'),
        content: Text(
          'Pinjamkan "${buku.judul}" kepada siswa ID ${hasil.siswaId} '
          'dengan jatuh tempo ${formatTanggal(hasil.tanggalJatuhTempo)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Pinjamkan'),
          ),
        ],
      ),
    );
    if (setuju != true) return;

    perpustakaanBloc.add(
      PerpustakaanPinjamRequested(
        bukuId: buku.id,
        siswaId: hasil.siswaId,
        tanggalPinjam: hasil.tanggalPinjam,
        tanggalJatuhTempo: hasil.tanggalJatuhTempo,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Buku'), centerTitle: true),
      body: BlocListener<PerpustakaanBloc, PerpustakaanState>(
        listenWhen: (_, current) =>
            current is PerpustakaanActionSuccess ||
            current is PerpustakaanActionFailure,
        listener: (context, state) {
          final messenger = ScaffoldMessenger.of(context);
          if (state is PerpustakaanActionSuccess) {
            messenger.showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.success,
              ),
            );
            // Stok & riwayat berubah setelah peminjaman dibuat.
            context.read<BukuDetailBloc>().add(
              const BukuDetailRefreshRequested(),
            );
          } else if (state is PerpustakaanActionFailure) {
            messenger.showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        child: BlocBuilder<BukuDetailBloc, BukuDetailState>(
          builder: (context, state) {
            if (state is BukuDetailInitial || state is BukuDetailLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is BukuDetailError) {
              return PerpustakaanErrorView(
                message: state.message,
                onRetry: () => context.read<BukuDetailBloc>().add(
                  const BukuDetailRefreshRequested(),
                ),
              );
            }

            if (state is! BukuDetailLoaded) return const SizedBox.shrink();

            return RefreshIndicator(
              onRefresh: () async {
                context.read<BukuDetailBloc>().add(
                  const BukuDetailRefreshRequested(),
                );
              },
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: Responsive.lebarKontenMaks(context),
                  ),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      Responsive.pagePadding(context).left,
                      12,
                      Responsive.pagePadding(context).right,
                      28,
                    ),
                    children: [
                      _KartuInfoBuku(state: state),
                      if (canPinjam) ...[
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: state.buku.tersedia
                              ? () => _pinjam(context, state.buku)
                              : null,
                          icon: const Icon(Icons.library_add_outlined),
                          label: Text(
                            state.buku.tersedia
                                ? 'Pinjamkan Buku'
                                : 'Stok Tidak Tersedia',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      if (state.riwayatDiminta) ...[
                        const SizedBox(height: 16),
                        _BagianRiwayat(state: state),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── Kartu info buku ──────────────────────────────────────────────────────────

class _KartuInfoBuku extends StatelessWidget {
  final BukuDetailLoaded state;

  const _KartuInfoBuku({required this.state});

  @override
  Widget build(BuildContext context) {
    final buku = state.buku;
    final warna = warnaKetersediaan(buku.stok);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 74,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.menu_book,
                    color: AppColors.primary,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        buku.judul,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        buku.penulis?.isNotEmpty == true
                            ? buku.penulis!
                            : 'Pengarang tidak diketahui',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      PerpustakaanBadge(
                        label: teksKetersediaan(
                          buku.stok,
                          total: state.totalEksemplar,
                        ),
                        color: warna,
                        icon: buku.tersedia
                            ? Icons.check_circle_outline
                            : Icons.remove_circle_outline,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 26),
            _BarisInfo(label: 'Penerbit', nilai: buku.penerbit ?? '-'),
            _BarisInfo(
              label: 'Tahun Terbit',
              nilai: buku.tahun?.toString() ?? '-',
            ),
            _BarisInfo(label: 'ISBN', nilai: buku.isbn ?? '-'),
            _BarisInfo(label: 'Stok Tersedia', nilai: '${buku.stok} eksemplar'),
            if (state.totalEksemplar != null)
              _BarisInfo(
                label: 'Total Eksemplar',
                nilai: '${state.totalEksemplar} eksemplar',
              ),
          ],
        ),
      ),
    );
  }
}

class _BarisInfo extends StatelessWidget {
  final String label;
  final String nilai;

  const _BarisInfo({required this.label, required this.nilai});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            // Kolom label dipersempit di layar sempit agar nilai tetap muat.
            width: Responsive.isCompact(context) ? 96 : 120,
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              nilai,
              style: const TextStyle(
                fontSize: 13,
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

// ── Riwayat peminjaman buku ──────────────────────────────────────────────────

class _BagianRiwayat extends StatelessWidget {
  final BukuDetailLoaded state;

  const _BagianRiwayat({required this.state});

  @override
  Widget build(BuildContext context) {
    final riwayat = state.riwayat;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.history, size: 18, color: AppColors.primary),
                SizedBox(width: 8),
                Text(
                  'Sedang Dipinjam',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Backend hanya mengirim peminjaman yang belum dikembalikan.',
              style: TextStyle(fontSize: 11, color: AppColors.textHint),
            ),
            const SizedBox(height: 12),
            if (state.riwayatError != null)
              Text(
                state.riwayatError!,
                style: const TextStyle(fontSize: 12, color: AppColors.error),
              )
            else if (riwayat == null || riwayat.peminjamanAktif.isEmpty)
              const Text(
                'Tidak ada eksemplar yang sedang dipinjam.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              )
            else
              ...riwayat.peminjamanAktif.map(_BarisPeminjam.new),
          ],
        ),
      ),
    );
  }
}

class _BarisPeminjam extends StatelessWidget {
  final PeminjamanAktifEntity item;

  const _BarisPeminjam(this.item);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.info.withAlpha(30),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.person_outline,
              size: 17,
              color: AppColors.info,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.siswaNama ?? 'Siswa #${item.siswaId ?? '-'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (item.siswaNis != null)
                  Text(
                    'NIS ${item.siswaNis}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textHint,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            formatTanggal(item.tanggalPinjam),
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
