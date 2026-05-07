import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/dashboard_entity.dart';
import 'dashboard_quick_actions.dart';

class WaliDashboardWidget extends StatelessWidget {
  final DashboardEntity data;

  const WaliDashboardWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final profile = data.profile ?? {};
    final children = data.children ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Text(
          'Selamat Datang, ${profile['nama'] ?? 'Wali'}',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Dashboard Orang Tua / Wali',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 20),

        // Children cards
        if (children.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Tidak ada data anak ditemukan.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ),
          )
        else
          ...children.map((child) => _ChildCard(child: child)),

        const SizedBox(height: 16),

        // Quick Actions
        const DashboardQuickActions(role: 'wali'),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _ChildCard extends StatelessWidget {
  final Map<String, dynamic> child;
  const _ChildCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final absensi = child['absensi_hari_ini']?.toString() ?? 'Belum Absen';
    final tunggakan = (child['tunggakan_spp_count'] as num?)?.toInt() ?? 0;

    Color absensiColor;
    IconData absensiIcon;
    if (absensi == 'Hadir') {
      absensiColor = AppColors.success;
      absensiIcon = Icons.check_circle;
    } else if (absensi == 'Belum Absen') {
      absensiColor = AppColors.textSecondary;
      absensiIcon = Icons.radio_button_unchecked;
    } else {
      absensiColor = AppColors.error;
      absensiIcon = Icons.warning_amber;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.info.withAlpha(30),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: AppColors.info,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        child['nama']?.toString() ?? 'Anak',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Kelas: ${child['kelas'] ?? '-'}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            _InfoRow(
              label: 'Kehadiran Hari Ini',
              value: absensi,
              valueColor: absensiColor,
              valueIcon: absensiIcon,
            ),
            const SizedBox(height: 8),
            _InfoRow(
              label: 'Tunggakan SPP',
              value: tunggakan == 0 ? 'Lunas' : '$tunggakan bulan',
              valueColor: tunggakan == 0 ? AppColors.success : AppColors.error,
              valueIcon: tunggakan == 0
                  ? Icons.check_circle
                  : Icons.attach_money,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final IconData valueIcon;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.valueIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(valueIcon, size: 14, color: valueColor),
            const SizedBox(width: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: valueColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
