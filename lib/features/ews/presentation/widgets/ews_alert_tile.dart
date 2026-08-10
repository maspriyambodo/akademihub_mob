import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/ews_alert_entity.dart';

class EwsAlertTile extends StatelessWidget {
  final EwsAlertEntity alert;
  final VoidCallback? onTap;
  final VoidCallback? onResolve;

  const EwsAlertTile({
    super.key,
    required this.alert,
    this.onTap,
    this.onResolve,
  });

  Color get _kategoriColor {
    switch (alert.kategori) {
      case 'absensi':
        return AppColors.warning;
      case 'nilai':
        return AppColors.info;
      case 'perilaku':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  Color get _levelColor {
    switch (alert.level) {
      case 1:
        return AppColors.warning;
      case 2:
        return Colors.deepOrange;
      case 3:
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData get _kategoriIcon {
    switch (alert.kategori) {
      case 'absensi':
        return Icons.event_busy;
      case 'nilai':
        return Icons.school;
      case 'perilaku':
        return Icons.psychology_alt;
      default:
        return Icons.warning_amber;
    }
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '-';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _kategoriColor.withAlpha(40),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(_kategoriIcon, color: _kategoriColor, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alert.kategoriLabel,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          'Siswa ID: ${alert.siswaId} · ${_formatDate(alert.tanggal)}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _levelColor.withAlpha(40),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      alert.levelLabel,
                      style: TextStyle(
                        color: _levelColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                alert.pesan,
                style: Theme.of(context).textTheme.bodyLarge,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              if (alert.dataPendukung != null &&
                  alert.dataPendukung!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: alert.dataPendukung!.entries
                      .take(3)
                      .map(
                        (e) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.divider.withAlpha(80),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${e.key}: ${e.value}',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  if (alert.isResolved)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withAlpha(40),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 14,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Selesai',
                            style: TextStyle(
                              color: AppColors.success,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (onResolve != null)
                    TextButton.icon(
                      onPressed: onResolve,
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Tandai Selesai'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 0,
                        ),
                        minimumSize: const Size(0, 32),
                      ),
                    ),
                  const Spacer(),
                  if (alert.tanggal != null)
                    Text(
                      _formatDate(alert.tanggal),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
