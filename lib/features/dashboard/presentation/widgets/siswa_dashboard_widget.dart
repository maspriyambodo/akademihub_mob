import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_metric_tile.dart';
import '../../../../core/widgets/app_section_header.dart';
import '../../../../core/widgets/app_surface_card.dart';
import '../../domain/entities/dashboard_entity.dart';
import 'dashboard_quick_actions.dart';

class SiswaDashboardWidget extends StatelessWidget {
  final DashboardEntity data;
  final List<String> permissions;

  const SiswaDashboardWidget({
    super.key,
    required this.data,
    required this.permissions,
  });

  @override
  Widget build(BuildContext context) {
    final attendanceSummary = data.attendanceSummary ?? [];
    final unpaidSpp = data.unpaidSpp ?? [];
    final recentGrades = data.recentGrades ?? [];
    final upcomingTasks = data.upcomingTasks ?? [];

    int hadirCount = 0, sakitCount = 0, izinCount = 0, alphaCount = 0;
    for (final item in attendanceSummary) {
      final label = (item['status_label'] ?? item['status'] ?? '')
          .toString()
          .toLowerCase();
      final total = (item['total'] as num?)?.toInt() ?? 0;
      if (label.contains('hadir')) {
        hadirCount += total;
      }
      if (label.contains('sakit')) {
        sakitCount += total;
      }
      if (label.contains('izin')) {
        izinCount += total;
      }
      if (label.contains('alpha') || label.contains('alpa')) {
        alphaCount += total;
      }
    }

    final hasTugasRoute =
        permissions.contains('tugas.view') ||
        permissions.contains('tugas-siswa.view');
    final hasNilaiRoute = permissions.contains('nilai.view');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Kehadiran Section
        const AppSectionHeader(
          title: 'Ringkasan Kehadiran',
          eyebrow: 'Presensi',
        ),
        const SizedBox(height: AppSpacing.sm),
        LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < Responsive.compactWidth;
            final tiles = [
              AppMetricTile(
                label: 'Hadir',
                value: '$hadirCount',
                icon: Icons.check_circle_outline,
                tone: AppStatusTone.success,
              ),
              AppMetricTile(
                label: 'Sakit',
                value: '$sakitCount',
                icon: Icons.local_hospital_outlined,
                tone: AppStatusTone.warning,
              ),
              AppMetricTile(
                label: 'Izin',
                value: '$izinCount',
                icon: Icons.info_outline,
                tone: AppStatusTone.info,
              ),
              AppMetricTile(
                label: 'Alpha',
                value: '$alphaCount',
                icon: Icons.highlight_off,
                tone: AppStatusTone.error,
              ),
            ];

            if (isCompact) {
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: tiles[0]),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(child: tiles[1]),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Expanded(child: tiles[2]),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(child: tiles[3]),
                    ],
                  ),
                ],
              );
            }

            return Row(
              children: [
                for (int i = 0; i < tiles.length; i++) ...[
                  if (i > 0) const SizedBox(width: AppSpacing.xs),
                  Expanded(child: tiles[i]),
                ],
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.lg),

        // 2. Akses Cepat
        DashboardQuickActions(role: 'siswa', permissions: permissions),
        const SizedBox(height: AppSpacing.lg),

        // 3. Tugas Mendatang
        if (upcomingTasks.isNotEmpty) ...[
          AppSectionHeader(
            title: 'Tugas Mendatang',
            eyebrow: 'Akademik',
            actionLabel: hasTugasRoute ? 'Lihat Semua' : null,
            onAction: hasTugasRoute
                ? () => context.push(AppRoutes.tugas)
                : null,
          ),
          const SizedBox(height: AppSpacing.sm),
          ...upcomingTasks
              .take(3)
              .map(
                (task) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: AppSurfaceCard(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: const Icon(
                            Icons.assignment_outlined,
                            color: AppColors.ink,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                task['judul'] ?? task['nama'] ?? 'Tugas',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
                                      color: AppColors.ink,
                                      fontWeight: FontWeight.w600,
                                    ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (task['deadline'] != null ||
                                  task['batas_waktu'] != null) ...[
                                const SizedBox(height: AppSpacing.xxs),
                                Text(
                                  'Tenggat: ${task['deadline'] ?? task['batas_waktu']}',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: AppColors.inkMuted),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          const SizedBox(height: AppSpacing.lg),
        ],

        // 4. Nilai Terbaru
        if (recentGrades.isNotEmpty) ...[
          AppSectionHeader(
            title: 'Nilai Terbaru',
            eyebrow: 'Hasil Belajar',
            actionLabel: hasNilaiRoute ? 'Lihat Semua' : null,
            onAction: hasNilaiRoute
                ? () => context.push(AppRoutes.nilai)
                : null,
          ),
          const SizedBox(height: AppSpacing.sm),
          ...recentGrades
              .take(3)
              .map(
                (grade) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: AppSurfaceCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight.withValues(
                              alpha: 0.5,
                            ),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: const Icon(
                            Icons.grade_outlined,
                            color: AppColors.primaryDark,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                grade['mapel'] ??
                                    grade['judul'] ??
                                    'Mata Pelajaran',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.ink,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (grade['tipe'] != null)
                                Text(
                                  '${grade['tipe']}',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: AppColors.inkMuted,
                                        fontSize: 11,
                                      ),
                                ),
                            ],
                          ),
                        ),
                        Text(
                          '${grade['nilai'] ?? '-'}',
                          style:
                              (Theme.of(
                                        context,
                                      ).extension<AppDataTypography>()?.value ??
                                      Theme.of(context).textTheme.titleMedium ??
                                      const TextStyle())
                                  .copyWith(
                                    color: AppColors.primaryDark,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          const SizedBox(height: AppSpacing.lg),
        ],

        // 5. Tagihan SPP (jika ada)
        if (unpaidSpp.isNotEmpty) ...[
          const AppSectionHeader(title: 'Tagihan SPP', eyebrow: 'Administrasi'),
          const SizedBox(height: AppSpacing.sm),
          AppSurfaceCard(
            accentColor: AppColors.warning,
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.warningContainer,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: AppColors.warningOnContainer,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${unpaidSpp.length} Bulan Belum Lunas',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Silakan hubungi bagian administrasi keuangan sekolah.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.inkSoft,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
