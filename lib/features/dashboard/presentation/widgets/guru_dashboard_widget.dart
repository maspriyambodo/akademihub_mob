import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_metric_tile.dart';
import '../../../../core/widgets/app_section_header.dart';
import '../../../../core/widgets/app_surface_card.dart';
import '../../domain/entities/dashboard_entity.dart';
import 'dashboard_quick_actions.dart';

class GuruDashboardWidget extends StatelessWidget {
  final DashboardEntity data;
  final List<String> permissions;

  const GuruDashboardWidget({
    super.key,
    required this.data,
    required this.permissions,
  });

  @override
  Widget build(BuildContext context) {
    final summary = data.summary ?? {};
    final recentBkCases = data.recentBkCases ?? [];

    final totalSiswaWali = (summary['total_siswa_wali'] as num?)?.toInt() ?? 0;
    final totalMapel =
        (summary['total_mapel'] as num?)?.toInt() ??
        (summary['total_mata_pelajaran'] as num?)?.toInt() ??
        0;
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
        // 1. Ringkasan Guru Metrics
        const AppSectionHeader(
          title: 'Aktivitas Mengajar',
          eyebrow: 'Akademik',
        ),
        const SizedBox(height: AppSpacing.sm),
        Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: AppMetricTile(
                    label: 'Siswa Perwalian',
                    value: '$totalSiswaWali',
                    icon: Icons.people_outline,
                    tone: AppStatusTone.info,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: AppMetricTile(
                    label: 'Mata Pelajaran',
                    value: '$totalMapel',
                    icon: Icons.menu_book_outlined,
                    tone: AppStatusTone.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Expanded(
                  child: AppMetricTile(
                    label: 'Kelas Wali',
                    value: '$totalKelasWali',
                    icon: Icons.school_outlined,
                    tone: AppStatusTone.neutral,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: AppMetricTile(
                    label: 'Tugas Belum Dinilai',
                    value: '$tugasBelumDinilai',
                    icon: Icons.assignment_late_outlined,
                    tone: tugasBelumDinilai > 0
                        ? AppStatusTone.warning
                        : AppStatusTone.neutral,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // 2. Status Presensi Guru Hari Ini
        const AppSectionHeader(
          title: 'Presensi Hari Ini',
          eyebrow: 'Kehadiran',
        ),
        const SizedBox(height: AppSpacing.sm),
        AppSurfaceCard(
          accentColor: sudahAbsen ? AppColors.success : AppColors.warning,
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: sudahAbsen
                      ? AppColors.successContainer
                      : AppColors.warningContainer,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  sudahAbsen
                      ? Icons.check_circle_outline
                      : Icons.schedule_outlined,
                  color: sudahAbsen
                      ? AppColors.successOnContainer
                      : AppColors.warningOnContainer,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sudahAbsen
                          ? 'Presensi Sudah Tercatat'
                          : 'Belum Melakukan Presensi',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sudahAbsen
                          ? 'Kehadiran guru Anda hari ini telah tervalidasi.'
                          : 'Silakan lakukan presensi melalui menu Absensi.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppColors.inkSoft),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // 3. Layanan & Akses Cepat
        DashboardQuickActions(role: 'guru', permissions: permissions),
        const SizedBox(height: AppSpacing.lg),

        // 4. Kasus BK Terbaru (bila ada)
        if (recentBkCases.isNotEmpty) ...[
          const AppSectionHeader(
            title: 'Kasus BK Terkait',
            eyebrow: 'Konseling',
          ),
          const SizedBox(height: AppSpacing.sm),
          ...recentBkCases.take(3).map((k) {
            final siswa = k['siswa'] as Map<String, dynamic>?;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: AppSurfaceCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.errorContainer,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.errorOnContainer,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            siswa?['nama'] ?? 'Siswa',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.ink,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            k['deskripsi'] ?? k['judul'] ?? 'Kasus BK',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.inkSoft),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ],
    );
  }
}
