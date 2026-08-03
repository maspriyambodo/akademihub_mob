import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';

/// Kartu bersudut tumpul dengan judul + ikon, dipakai semua seksi di halaman
/// profil supaya tampilannya konsisten.
class ProfilInfoCard extends StatelessWidget {
  final String judul;
  final IconData ikon;
  final Color? warnaIkon;
  final Widget? aksi;
  final List<Widget> children;

  const ProfilInfoCard({
    super.key,
    required this.judul,
    required this.ikon,
    this.warnaIkon,
    this.aksi,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final warna = warnaIkon ?? AppColors.primary;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: warna.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(ikon, size: 18, color: warna),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    judul,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                ?aksi,
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: 4),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// Satu baris "label — nilai". Hanya dipakai bila nilainya benar-benar ada.
class ProfilInfoRow extends StatelessWidget {
  final IconData ikon;
  final String label;
  final String nilai;

  const ProfilInfoRow({
    super.key,
    required this.ikon,
    required this.label,
    required this.nilai,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(ikon, size: 18, color: AppColors.textSecondary),
          SizedBox(width: Responsive.isCompact(context) ? 8 : 12),
          SizedBox(
            // Label dipersempit di layar kecil supaya nilai panjang
            // (alamat, email, nama sekolah) tetap punya ruang baca.
            width: Responsive.isCompact(context) ? 88 : 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              nilai,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
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

/// Pesan singkat di dalam kartu (kosong / gagal muat) plus tombol coba lagi.
class ProfilCardMessage extends StatelessWidget {
  final IconData ikon;
  final String pesan;
  final Color? warna;
  final VoidCallback? onRetry;

  const ProfilCardMessage({
    super.key,
    required this.ikon,
    required this.pesan,
    this.warna,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final c = warna ?? AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Icon(ikon, size: 32, color: c),
          const SizedBox(height: 8),
          Text(
            pesan,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: c),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Coba Lagi'),
            ),
          ],
        ],
      ),
    );
  }
}
