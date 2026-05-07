import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/dashboard_entity.dart';
import 'dashboard_stat_card.dart';
import 'dashboard_quick_actions.dart';

class GuruDashboardWidget extends StatelessWidget {
  final DashboardEntity data;

  const GuruDashboardWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final profile = data.profile ?? {};
    final summary = data.summary ?? {};
    final recentBkCases = data.recentBkCases ?? [];

    final totalSiswaWali = (summary['total_siswa_wali'] as num?)?.toInt() ?? 0;
    final totalMapel = (summary['total_mata_pelajaran'] as num?)?.toInt() ?? 0;
    final totalKelasWali = (summary['total_kelas_wali'] as num?)?.toInt() ?? 0;
    final tugasBelumDinilai =
        (summary['tugas_belum_dinilai'] as num?)?.toInt() ?? 0;

    final sudahAbsen =
        summary['sudah_absen_hari_ini'] == true ||
        summary['has_absen_hari_ini'] == true ||
        summary['is_absen_hari_ini'] == true ||
        (summary['total_hadir_hari_ini'] != null &&
            (summary['total_hadir_hari_ini'] as num) > 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Text(
          'Selamat Datang, ${profile['nama'] ?? 'Guru'}',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'NIP: ${profile['nip'] ?? '-'}',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 20),

        // Stat cards
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.4,
          children: [
            DashboardStatCard(
              title: 'Siswa Perwalian',
              value: '$totalSiswaWali',
              icon: Icons.people,
              color: AppColors.info,
            ),
            DashboardStatCard(
              title: 'Mata Pelajaran',
              value: '$totalMapel',
              icon: Icons.menu_book,
              color: AppColors.success,
            ),
            DashboardStatCard(
              title: 'Kelas Wali',
              value: '$totalKelasWali',
              icon: Icons.school,
              color: Colors.purple,
            ),
            DashboardStatCard(
              title: 'Tugas Belum Dinilai',
              value: '$tugasBelumDinilai',
              icon: Icons.assignment_late,
              color: AppColors.warning,
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Attendance status card
        DashboardStatCard(
          title: 'Sudah Absen Hari Ini',
          value: sudahAbsen ? 'Ya' : 'Belum',
          icon: sudahAbsen ? Icons.check_circle : Icons.radio_button_unchecked,
          color: sudahAbsen ? AppColors.success : AppColors.textSecondary,
          description: sudahAbsen
              ? 'Status kehadiran guru hari ini sudah tercatat'
              : 'Silakan lakukan absen melalui menu Absensi',
        ),
        const SizedBox(height: 16),

        // Recent BK Cases
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kasus BK Terbaru',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                if (recentBkCases.isEmpty)
                  Text(
                    'Tidak ada kasus BK terbaru.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  )
                else
                  ...recentBkCases.map((k) => _BkCaseRow(kasus: k)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Quick Actions
        const DashboardQuickActions(role: 'guru'),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _BkCaseRow extends StatelessWidget {
  final Map<String, dynamic> kasus;
  const _BkCaseRow({required this.kasus});

  @override
  Widget build(BuildContext context) {
    final siswa = kasus['siswa'] as Map<String, dynamic>?;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.error.withAlpha(30),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.warning_amber,
              color: AppColors.error,
              size: 14,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  siswa?['nama'] ?? 'Siswa',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
                ),
                Text(
                  kasus['deskripsi'] ?? kasus['judul'] ?? 'Kasus BK',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
