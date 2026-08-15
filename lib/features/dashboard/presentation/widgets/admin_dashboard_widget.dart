import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../domain/entities/dashboard_entity.dart';
import 'dashboard_stat_card.dart';
import 'dashboard_quick_actions.dart';

class AdminDashboardWidget extends StatelessWidget {
  final DashboardEntity data;
  final List<String> permissions;

  const AdminDashboardWidget({
    super.key,
    required this.data,
    required this.permissions,
  });

  @override
  Widget build(BuildContext context) {
    final cards = data.summaryCards ?? {};

    final totalSiswa = (cards['total_siswa_aktif'] as num?)?.toInt() ?? 0;
    final totalGuru = (cards['total_guru'] as num?)?.toInt() ?? 0;
    final totalKelas = (cards['total_kelas'] as num?)?.toInt() ?? 0;
    final kasusBk = (cards['kasus_bk_proses'] as num?)?.toInt() ?? 0;

    final tunggakan = cards['total_tunggakan_spp'] as Map<String, dynamic>?;
    final tunggakanFormatted = tunggakan?['formatted'] as String? ?? 'Rp 0';
    final tunggakanDesc =
        '${tunggakan?['month'] ?? ''} ${tunggakan?['year'] ?? ''} · '
        '${tunggakan?['jumlah_siswa'] ?? 0} siswa';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Text(
          'Dashboard Overview',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'School Management System Analytics',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 20),

        // Summary stat cards
        GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: Responsive.gridDelegate(context, tinggi: 140),
          children: [
            DashboardStatCard(
              title: 'Total Siswa Aktif',
              value: '$totalSiswa',
              icon: Icons.people,
              color: AppColors.info,
            ),
            DashboardStatCard(
              title: 'Total Guru',
              value: '$totalGuru',
              icon: Icons.menu_book,
              color: AppColors.success,
            ),
            DashboardStatCard(
              title: 'Total Kelas',
              value: '$totalKelas',
              icon: Icons.school,
              color: Colors.purple,
            ),
            DashboardStatCard(
              title: 'Kasus BK Proses',
              value: '$kasusBk',
              icon: Icons.warning_amber,
              color: AppColors.error,
            ),
          ],
        ),
        const SizedBox(height: 10),

        DashboardStatCard(
          title: 'Tunggakan SPP',
          value: tunggakanFormatted,
          icon: Icons.attach_money,
          color: AppColors.warning,
          description: tunggakanDesc.trim().isNotEmpty ? tunggakanDesc : null,
        ),
        const SizedBox(height: 10),

        // Quick Actions
        DashboardQuickActions(role: 'admin', permissions: permissions),
        const SizedBox(height: 16),
      ],
    );
  }
}
