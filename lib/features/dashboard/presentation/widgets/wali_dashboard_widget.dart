import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_section_header.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../../../core/widgets/app_surface_card.dart';
import '../../domain/entities/dashboard_entity.dart';
import 'dashboard_quick_actions.dart';

class WaliDashboardWidget extends StatelessWidget {
  final DashboardEntity data;
  final List<String> permissions;

  const WaliDashboardWidget({
    super.key,
    required this.data,
    required this.permissions,
  });

  @override
  Widget build(BuildContext context) {
    final children = data.children ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Data Siswa Asuhan / Perwalian
        const AppSectionHeader(
          title: 'Status Anak Asuhan',
          eyebrow: 'Keluarga',
        ),
        const SizedBox(height: AppSpacing.sm),
        if (children.isEmpty)
          AppSurfaceCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.inkMuted),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Tidak ada data anak yang terhubung dengan akun ini.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.inkSoft),
                  ),
                ),
              ],
            ),
          )
        else
          ...children.map((child) => _ChildCard(child: child)),

        const SizedBox(height: AppSpacing.lg),

        // 2. Akses Cepat Wali
        DashboardQuickActions(
          role: 'wali',
          permissions: permissions,
          hasChild: children.isNotEmpty,
        ),
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

    final AppStatusTone tone;
    final IconData absensiIcon;
    if (absensi.toLowerCase().contains('hadir')) {
      tone = AppStatusTone.success;
      absensiIcon = Icons.check_circle_outline;
    } else if (absensi.toLowerCase().contains('belum')) {
      tone = AppStatusTone.neutral;
      absensiIcon = Icons.schedule_outlined;
    } else {
      tone = AppStatusTone.error;
      absensiIcon = Icons.warning_amber_rounded;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppSurfaceCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.waliContainer,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: const Icon(
                    Icons.face_outlined,
                    color: AppColors.waliOnContainer,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        child['nama']?.toString() ?? 'Anak',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Kelas: ${child['kelas'] ?? '-'}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.inkSoft,
                        ),
                      ),
                    ],
                  ),
                ),
                AppStatusBadge(label: absensi, tone: tone, icon: absensiIcon),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            const Divider(color: AppColors.line),
            const SizedBox(height: AppSpacing.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Status SPP',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.inkSoft),
                ),
                AppStatusBadge(
                  label: tunggakan == 0
                      ? 'Lunas'
                      : '$tunggakan Bulan Tunggakan',
                  tone: tunggakan == 0
                      ? AppStatusTone.success
                      : AppStatusTone.warning,
                  icon: tunggakan == 0
                      ? Icons.check_circle_outline
                      : Icons.payments_outlined,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
