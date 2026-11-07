import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
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
        // 0. Live KBM Hari Ini
        const _LiveKbmCard(),
        const SizedBox(height: AppSpacing.md),

        // 1. Ringkasan Presensi Card
        _RingkasanPresensiCard(
          hadir: hadirCount,
          sakit: sakitCount,
          izin: izinCount,
          alpha: alphaCount,
        ),
        const SizedBox(height: AppSpacing.md),

        // 2. Featured Bento Hub
        _FeaturedBentoRow(upcomingTaskCount: upcomingTasks.length),
        const SizedBox(height: AppSpacing.lg),

        // 3. Akses Cepat
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
                        // ponytail: Academic task icon container; add subject-specific badge coloring when course taxonomy lands.
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.secondary.withValues(alpha: 0.22),
                                AppColors.secondary.withValues(alpha: 0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(
                              color: AppColors.secondary.withValues(alpha: 0.35),
                              width: 1,
                            ),
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
                                      fontWeight: FontWeight.w700,
                                    ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (task['deadline'] != null ||
                                  task['batas_waktu'] != null) ...[
                                const SizedBox(height: AppSpacing.xxs),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.paperMuted,
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.sm,
                                    ),
                                    border: Border.all(
                                      color: AppColors.line.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    'Tenggat: ${task['deadline'] ?? task['batas_waktu']}',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: AppColors.inkSoft,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
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
                              alpha: 0.6,
                            ),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.25),
                              width: 1,
                            ),
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
                                      fontWeight: FontWeight.w700,
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
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.25),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '${grade['nilai'] ?? '-'}',
                            style:
                                (Theme.of(
                                          context,
                                        ).extension<AppDataTypography>()?.value ??
                                        Theme.of(context).textTheme.titleMedium ??
                                        const TextStyle())
                                    .copyWith(
                                      color: AppColors.primaryDark,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
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

class _LiveKbmCard extends StatelessWidget {
  const _LiveKbmCard();

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.access_time_filled, size: 12, color: AppColors.primary),
                    SizedBox(width: 4),
                    Text(
                      'KBM HARI INI',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () => context.push(AppRoutes.jadwal),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: const Row(
                  children: [
                    Text(
                      'Jadwal Lengkap',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppColors.primary),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: const Column(
                  children: [
                    Text(
                      '07:30',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF15803D)),
                    ),
                    Text(
                      '09:00',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF16A34A)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Matematika Peminatan',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 13, color: AppColors.inkMuted),
                        SizedBox(width: 3),
                        Text('Lab 2', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.inkSoft)),
                        SizedBox(width: 6),
                        Text('•  Drs. Bambang H., M.Pd', style: TextStyle(fontSize: 11.5, color: AppColors.inkMuted)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeaturedBentoRow extends StatelessWidget {
  final int upcomingTaskCount;
  const _FeaturedBentoRow({required this.upcomingTaskCount});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AppSurfaceCard(
            onTap: () => context.push(AppRoutes.ujian),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(color: const Color(0xFFC7D2FE)),
                  ),
                  child: const Icon(Icons.quiz_outlined, size: 20, color: Color(0xFF4F46E5)),
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'CBT & Ujian',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Asesmen Digital',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.inkMuted),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: AppSurfaceCard(
            onTap: () => context.push(AppRoutes.tugas),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: const Icon(Icons.assignment_turned_in_outlined, size: 20, color: Color(0xFFD97706)),
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Tugas & PR',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink),
                ),
                const SizedBox(height: 2),
                Text(
                  '$upcomingTaskCount Tugas Aktif',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFD97706)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RingkasanPresensiCard extends StatelessWidget {
  final int hadir;
  final int sakit;
  final int izin;
  final int alpha;

  const _RingkasanPresensiCard({
    required this.hadir,
    required this.sakit,
    required this.izin,
    required this.alpha,
  });

  Widget _chip({
    required String label,
    required String count,
    required IconData icon,
    required Color bg,
    required Color border,
    required Color text,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: border, width: 1),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 12, color: text),
                const SizedBox(width: 3),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: text,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              count,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.how_to_reg_outlined, size: 18, color: AppColors.primary),
              SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PRESENSI',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    'Ringkasan Kehadiran',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
              Spacer(),
              Text(
                'Semester Genap',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.inkMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _chip(
                label: 'Hadir',
                count: '$hadir',
                icon: Icons.check_circle_outline,
                bg: const Color(0xFFF0FDF4),
                border: const Color(0xFFBBF7D0),
                text: const Color(0xFF16A34A),
              ),
              const SizedBox(width: 6),
              _chip(
                label: 'Sakit',
                count: '$sakit',
                icon: Icons.local_hospital_outlined,
                bg: const Color(0xFFFEFCE8),
                border: const Color(0xFFFEF08A),
                text: const Color(0xFFCA8A04),
              ),
              const SizedBox(width: 6),
              _chip(
                label: 'Izin',
                count: '$izin',
                icon: Icons.info_outline,
                bg: const Color(0xFFF0F9FF),
                border: const Color(0xFFBAE6FD),
                text: const Color(0xFF0284C7),
              ),
              const SizedBox(width: 6),
              _chip(
                label: 'Alpha',
                count: '$alpha',
                icon: Icons.highlight_off,
                bg: const Color(0xFFFEF2F2),
                border: const Color(0xFFFECACA),
                text: const Color(0xFFDC2626),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.paperMuted,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time_rounded, size: 15, color: AppColors.inkSoft),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'Presensi Hari Ini: Belum Masuk',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.inkSoft,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => context.push(AppRoutes.absensi),
                  child: const Text(
                    'Presensi Mandiri →',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
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

