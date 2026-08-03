import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/perangkat_entity.dart';
import 'profil_info_card.dart';
import 'profil_visuals.dart';

/// Kartu "Perangkat Login" — hanya ditampilkan untuk user dengan permission
/// `users.view` (siswa & wali tidak punya).
class PerangkatCard extends StatelessWidget {
  final List<PerangkatEntity> items;
  final String? error;
  final VoidCallback onRetry;

  const PerangkatCard({
    super.key,
    required this.items,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return ProfilInfoCard(
      judul: 'Perangkat Login',
      ikon: Icons.devices_outlined,
      warnaIkon: AppColors.info,
      aksi: items.isEmpty
          ? null
          : Text(
              '${items.length}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
      children: [
        if (error != null)
          ProfilCardMessage(
            ikon: Icons.cloud_off_outlined,
            pesan: error!,
            warna: AppColors.error,
            onRetry: onRetry,
          )
        else if (items.isEmpty)
          const ProfilCardMessage(
            ikon: Icons.devices_other,
            pesan: 'Belum ada perangkat yang terdaftar',
          )
        else
          ...items.map((e) => _PerangkatTile(perangkat: e)),
      ],
    );
  }
}

class _PerangkatTile extends StatelessWidget {
  final PerangkatEntity perangkat;

  const _PerangkatTile({required this.perangkat});

  @override
  Widget build(BuildContext context) {
    final versi = perangkat.appVersion;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.info.withAlpha(30),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              ikonPerangkat(perangkat.deviceType),
              size: 18,
              color: AppColors.info,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  versi == null || versi.isEmpty
                      ? labelPerangkat(perangkat.deviceType)
                      : '${labelPerangkat(perangkat.deviceType)} · v$versi',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  perangkat.lastActiveAt == null
                      ? 'Belum pernah aktif'
                      : 'Aktif ${waktuRelatif(perangkat.lastActiveAt)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (perangkat.createdAt != null)
                  Text(
                    'Terdaftar ${waktuLengkap(perangkat.createdAt)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textHint,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
