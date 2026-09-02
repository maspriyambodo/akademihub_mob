import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_metric_tile.dart';
import '../../../../core/widgets/app_section_header.dart';
import '../../../../core/widgets/app_surface_card.dart';
import '../../domain/entities/dashboard_entity.dart';
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
        // 1. Ringkasan Operasional Sekolah
        const AppSectionHeader(
          title: 'Statistik Sekolah',
          eyebrow: 'Administrasi',
        ),
        const SizedBox(height: AppSpacing.sm),
        Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: AppMetricTile(
                    label: 'Total Siswa Aktif',
                    value: '$totalSiswa',
                    icon: Icons.people_outline,
                    tone: AppStatusTone.info,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: AppMetricTile(
                    label: 'Total Guru',
                    value: '$totalGuru',
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
                    label: 'Total Kelas',
                    value: '$totalKelas',
                    icon: Icons.school_outlined,
                    tone: AppStatusTone.neutral,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: AppMetricTile(
                    label: 'Kasus BK Aktif',
                    value: '$kasusBk',
                    icon: Icons.warning_amber_rounded,
                    tone: kasusBk > 0
                        ? AppStatusTone.error
                        : AppStatusTone.neutral,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // Tunggakan SPP Highlight
        AppSurfaceCard(
          accentColor: AppColors.warning,
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.warningContainer,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: AppColors.warningOnContainer,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tunggakan SPP Sekolah',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.inkMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tunggakanFormatted,
                      style:
                          (Theme.of(
                                    context,
                                  ).extension<AppDataTypography>()?.value ??
                                  Theme.of(context).textTheme.titleLarge ??
                                  const TextStyle())
                              .copyWith(
                                color: AppColors.warningOnContainer,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                    ),
                    if (tunggakanDesc.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        tunggakanDesc,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.inkSoft,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // 2. Akses Cepat Admin
        DashboardQuickActions(role: 'admin', permissions: permissions),
      ],
    );
  }
}
