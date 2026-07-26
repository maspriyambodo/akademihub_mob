import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/pembayaran_spp_entity.dart';
import '../bloc/keuangan_aksi_status.dart';
import '../bloc/keuangan_detail_bloc.dart';
import '../widgets/keuangan_format.dart';

/// Halaman detail satu tagihan / pembayaran SPP.
///
/// [pembayaran] adalah item dari daftar; dipakai untuk mengisi header lebih
/// cepat dan sebagai cadangan bila endpoint show tidak mengirim relasi
/// tertentu. Data resmi tetap diambil ulang dari
/// `GET /keuangan/pembayaran-spp/{id}`.
class KeuanganDetailPage extends StatelessWidget {
  final PembayaranSppEntity pembayaran;

  /// Punya permission `pembayaran-spp.bayar`.
  final bool canBayar;

  /// Mode admin/petugas — menampilkan aksi pencatatan pembayaran manual.
  final bool modeAdmin;

  const KeuanganDetailPage({
    super.key,
    required this.pembayaran,
    this.canBayar = false,
    this.modeAdmin = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<KeuanganDetailBloc>()
        ..add(KeuanganDetailLoadRequested(pembayaran.id)),
      child: _KeuanganDetailView(
        awal: pembayaran,
        canBayar: canBayar,
        modeAdmin: modeAdmin,
      ),
    );
  }
}

class _KeuanganDetailView extends StatelessWidget {
  final PembayaranSppEntity awal;
  final bool canBayar;
  final bool modeAdmin;

  const _KeuanganDetailView({
    required this.awal,
    required this.canBayar,
    required this.modeAdmin,
  });

  Future<void> _bukaCheckout(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      _pesan(context, 'Tautan pembayaran tidak valid', gagal: true);
      return;
    }

    final berhasil = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!context.mounted) return;
    if (!berhasil) {
      _pesan(
        context,
        'Tidak dapat membuka halaman pembayaran. Salin tautan berikut:\n$url',
        gagal: true,
      );
    }
  }

  void _pesan(BuildContext context, String teks, {bool gagal = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(teks),
        backgroundColor: gagal ? AppColors.error : AppColors.success,
        duration: Duration(seconds: gagal ? 6 : 3),
      ),
    );
  }

  Future<void> _konfirmasiCatatLunas(BuildContext context) async {
    final bloc = context.read<KeuanganDetailBloc>();
    final setuju = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Catat Pelunasan'),
        content: const Text(
          'Tandai tagihan ini sebagai LUNAS dengan metode Tunai?\n\n'
          'Aksi ini mencatat pembayaran baru atas nama petugas yang sedang '
          'login dan tidak dapat dibatalkan dari aplikasi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Catat Lunas'),
          ),
        ],
      ),
    );

    if (setuju == true) {
      bloc.add(
        const KeuanganDetailBayarTunaiRequested(
          metodePembayaran: 1,
          keterangan: 'Pencatatan pelunasan via aplikasi mobile',
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Tagihan'), centerTitle: true),
      body: BlocConsumer<KeuanganDetailBloc, KeuanganDetailState>(
        listenWhen: (prev, curr) =>
            curr is KeuanganDetailLoaded &&
            (prev is! KeuanganDetailLoaded ||
                prev.aksiStatus != curr.aksiStatus),
        listener: (context, state) {
          if (state is! KeuanganDetailLoaded) return;

          if (state.aksiStatus == KeuanganAksiStatus.success) {
            final url = state.aksiUrl;
            if (url != null && url.isNotEmpty) {
              _bukaCheckout(context, url);
            } else {
              _pesan(context, state.aksiMessage ?? 'Aksi berhasil');
            }
          } else if (state.aksiStatus == KeuanganAksiStatus.failure) {
            _pesan(
              context,
              state.aksiMessage ?? 'Aksi gagal diproses',
              gagal: true,
            );
          }
        },
        builder: (context, state) {
          if (state is KeuanganDetailInitial || state is KeuanganDetailLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is KeuanganDetailError) {
            return _ErrorView(
              message: state.message,
              onRetry: () => context.read<KeuanganDetailBloc>().add(
                const KeuanganDetailRefreshRequested(),
              ),
            );
          }
          if (state is KeuanganDetailLoaded) {
            return RefreshIndicator(
              onRefresh: () async {
                context.read<KeuanganDetailBloc>().add(
                  const KeuanganDetailRefreshRequested(),
                );
              },
              child: _Isi(
                state: state,
                awal: awal,
                canBayar: canBayar,
                modeAdmin: modeAdmin,
                onBayarOnline: () => context.read<KeuanganDetailBloc>().add(
                  const KeuanganDetailBayarOnlineRequested(),
                ),
                onCatatLunas: () => _konfirmasiCatatLunas(context),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

// ── Isi halaman ──────────────────────────────────────────────────────────────

class _Isi extends StatelessWidget {
  final KeuanganDetailLoaded state;
  final PembayaranSppEntity awal;
  final bool canBayar;
  final bool modeAdmin;
  final VoidCallback onBayarOnline;
  final VoidCallback onCatatLunas;

  const _Isi({
    required this.state,
    required this.awal,
    required this.canBayar,
    required this.modeAdmin,
    required this.onBayarOnline,
    required this.onCatatLunas,
  });

  @override
  Widget build(BuildContext context) {
    final p = state.pembayaran;
    final denda = state.denda;
    final warna = warnaStatus(p.statusKey);
    final sedangProses = state.aksiStatus == KeuanganAksiStatus.loading;

    final double nominal =
        p.tarifNominal ?? denda?.nominal ?? p.jumlahBayar ?? 0.0;
    final double nilaiDenda = denda?.denda ?? 0.0;
    final total = p.isLunas
        ? (p.jumlahBayar ?? nominal)
        : (denda?.total ?? nominal);

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
                  children: [
                    Expanded(
                      child: Text(
                        p.labelPeriode,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    StatusBadge(
                      label: p.statusLabel,
                      color: warna,
                      icon: ikonStatus(p.statusKey),
                      besar: true,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  formatRupiah(total),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: p.isLunas ? AppColors.success : AppColors.error,
                  ),
                ),
                if (nilaiDenda > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Termasuk denda ${formatRupiah(nilaiDenda)}'
                    '${denda != null && denda.bulanTerlambat > 0 ? ' · terlambat ${denda.bulanTerlambat} bulan' : ''}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if ((p.kelasNama ?? awal.kelasNama) != null)
                      InfoChip(
                        icon: Icons.class_outlined,
                        label: (p.kelasNama ?? awal.kelasNama)!,
                        color: AppColors.info,
                      ),
                    if ((p.siswaNis ?? awal.siswaNis) != null)
                      InfoChip(
                        icon: Icons.badge_outlined,
                        label: 'NIS ${p.siswaNis ?? awal.siswaNis}',
                        color: AppColors.textSecondary,
                      ),
                    if (p.metodePembayaran != null &&
                        p.metodePembayaran!.isNotEmpty)
                      InfoChip(
                        icon: Icons.account_balance_wallet_outlined,
                        label: p.metodePembayaran!,
                        color: AppColors.primary,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // ── Rincian nominal ───────────────────────────────────────────────
        _Seksi(
          judul: 'Rincian Nominal',
          anak: [
            DetailRow(label: 'Tarif SPP', nilai: formatRupiah(nominal)),
            DetailRow(
              label: 'Denda keterlambatan',
              nilai: nilaiDenda > 0 ? formatRupiah(nilaiDenda) : 'Tidak ada',
              warnaNilai: nilaiDenda > 0 ? AppColors.error : null,
            ),
            if (denda != null && denda.dendaPersen > 0)
              DetailRow(
                label: 'Persentase denda',
                nilai: formatPersen(denda.dendaPersen),
              ),
            DetailRow(
              label: p.isLunas ? 'Jumlah dibayar' : 'Total tagihan',
              nilai: formatRupiah(total),
              tebal: true,
              warnaNilai: p.isLunas ? AppColors.success : AppColors.error,
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ── Rincian pembayaran ────────────────────────────────────────────
        _Seksi(
          judul: 'Rincian Pembayaran',
          anak: [
            DetailRow(
              label: 'Siswa',
              nilai: p.siswaNama ?? awal.siswaNama ?? '-',
            ),
            DetailRow(label: 'Bulan', nilai: namaBulan(p.bulan)),
            DetailRow(label: 'Tahun', nilai: p.tahun?.toString() ?? '-'),
            DetailRow(
              label: 'Metode bayar',
              nilai: (p.metodePembayaran == null || p.metodePembayaran!.isEmpty)
                  ? '-'
                  : p.metodePembayaran!,
            ),
            DetailRow(
              label: 'Tanggal bayar',
              nilai: formatTanggalPanjang(p.tanggalBayar),
            ),
            DetailRow(label: 'Status', nilai: p.statusLabel, warnaNilai: warna),
            DetailRow(label: 'Petugas', nilai: p.petugasNama ?? '-'),
            DetailRow(
              label: 'Dicatat pada',
              nilai: formatTanggalPanjang(p.createdAt),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ── Bukti / keterangan ────────────────────────────────────────────
        _Seksi(
          judul: 'Bukti / Keterangan',
          anak: [
            Text(
              (p.keterangan == null || p.keterangan!.trim().isEmpty)
                  ? 'Tidak ada keterangan atau bukti tambahan yang dicatat '
                        'petugas untuk tagihan ini.'
                  : p.keterangan!,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
          ],
        ),

        // ── Aksi ──────────────────────────────────────────────────────────
        if (!p.isLunas && canBayar) ...[
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: sedangProses ? null : onBayarOnline,
            icon: sedangProses
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.open_in_new),
            label: Text(
              sedangProses ? 'Memproses...' : 'Bayar Online (Midtrans)',
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Pembayaran diproses di halaman Midtrans yang terbuka di browser. '
            'Status akan diperbarui otomatis setelah pembayaran terkonfirmasi — '
            'tarik layar ke bawah untuk menyegarkan.',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          if (modeAdmin) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: sedangProses ? null : onCatatLunas,
              icon: const Icon(Icons.point_of_sale_outlined),
              label: const Text('Catat Pelunasan Tunai'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class _Seksi extends StatelessWidget {
  final String judul;
  final List<Widget> anak;

  const _Seksi({required this.judul, required this.anak});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              judul,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const Divider(height: 20, color: AppColors.divider),
            ...anak,
          ],
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
            ),
          ],
        ),
      ),
    );
  }
}
