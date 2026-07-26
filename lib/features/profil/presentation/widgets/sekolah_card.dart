import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/sekolah_entity.dart';
import 'profil_info_card.dart';

/// Kartu "Sekolah". Data lengkap (NPSN, alamat) hanya tersedia untuk user
/// dengan permission `sekolah.view`; selain itu memakai nama sekolah dari
/// tenant yang tersimpan di perangkat.
class SekolahCard extends StatelessWidget {
  final SekolahEntity? sekolah;
  final bool dariCache;
  final String? error;
  final VoidCallback onRetry;

  const SekolahCard({
    super.key,
    required this.sekolah,
    required this.dariCache,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final data = sekolah;

    return ProfilInfoCard(
      judul: 'Sekolah',
      ikon: Icons.account_balance_outlined,
      warnaIkon: AppColors.secondary,
      children: [
        if (data == null)
          ProfilCardMessage(
            ikon: error != null
                ? Icons.cloud_off_outlined
                : Icons.info_outline,
            pesan: error ?? 'Informasi sekolah belum tersedia',
            warna: error != null ? AppColors.error : null,
            onRetry: error != null ? onRetry : null,
          )
        else ...[
          ProfilInfoRow(
            ikon: Icons.school_outlined,
            label: 'Nama Sekolah',
            nilai: data.namaSekolah,
          ),
          if (data.npsn != null && data.npsn!.isNotEmpty)
            ProfilInfoRow(
              ikon: Icons.confirmation_number_outlined,
              label: 'NPSN',
              nilai: data.npsn!,
            ),
          if (data.alamat != null && data.alamat!.isNotEmpty)
            ProfilInfoRow(
              ikon: Icons.location_on_outlined,
              label: 'Alamat',
              nilai: data.alamat!,
            ),
          if (dariCache)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                'Detail sekolah terbatas — akun ini tidak memiliki akses '
                'data sekolah.',
                style: TextStyle(fontSize: 11, color: AppColors.textHint),
              ),
            ),
        ],
      ],
    );
  }
}
