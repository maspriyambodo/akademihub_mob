import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../domain/entities/notification_entity.dart';
import 'notification_visuals.dart';

/// Satu baris notifikasi. Item belum dibaca dibedakan dengan latar biru tipis,
/// judul tebal, dan titik penanda di sisi kanan.
class NotificationTile extends StatelessWidget {
  final NotificationEntity item;
  final VoidCallback onTap;

  const NotificationTile({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final visual = visualForType(item.type);
    final unread = !item.isRead;
    final pad = Responsive.pagePadding(context);

    return Material(
      color: unread ? AppColors.primary.withAlpha(15) : AppColors.cardBg,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: pad.left, vertical: 14),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppColors.divider, width: 0.6),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Ikon per tipe ───────────────────────────────────────────
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: visual.color.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(visual.icon, color: visual.color, size: 22),
              ),
              const SizedBox(width: 12),

              // ── Konten ──────────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.judul.isEmpty ? visual.label : item.judul,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.3,
                        color: AppColors.textPrimary,
                        fontWeight: unread ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.pesan,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Chip tipe + waktu relatif: keduanya fleksibel supaya
                    // baris ini tidak pernah meluber di layar sempit.
                    Row(
                      children: [
                        Flexible(
                          child: _TypeChip(
                            label: visual.label,
                            color: visual.color,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            waktuRelatif(item.createdAt),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textHint,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Titik penanda belum dibaca ──────────────────────────────
              if (unread)
                Container(
                  margin: const EdgeInsets.only(left: 8, top: 6),
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final Color color;

  const _TypeChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
