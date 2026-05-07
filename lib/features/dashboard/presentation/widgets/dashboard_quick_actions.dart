import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';

class _QuickAction {
  final String label;
  final IconData icon;
  final String route;
  final Color color;

  const _QuickAction({
    required this.label,
    required this.icon,
    required this.route,
    required this.color,
  });
}

const _adminActions = [
  _QuickAction(
    label: 'Absensi',
    icon: Icons.checklist,
    route: AppRoutes.absensi,
    color: AppColors.info,
  ),
  _QuickAction(
    label: 'Nilai',
    icon: Icons.grade,
    route: AppRoutes.nilai,
    color: AppColors.success,
  ),
  _QuickAction(
    label: 'Jadwal',
    icon: Icons.calendar_today,
    route: AppRoutes.jadwal,
    color: AppColors.primary,
  ),
  _QuickAction(
    label: 'Tugas',
    icon: Icons.assignment,
    route: AppRoutes.tugas,
    color: AppColors.secondary,
  ),
  _QuickAction(
    label: 'Rapor',
    icon: Icons.book,
    route: AppRoutes.rapor,
    color: AppColors.accent,
  ),
  _QuickAction(
    label: 'Notifikasi',
    icon: Icons.notifications,
    route: AppRoutes.notifications,
    color: AppColors.warning,
  ),
];

const _guruActions = [
  _QuickAction(
    label: 'Jadwal Pelajaran',
    icon: Icons.calendar_today,
    route: AppRoutes.jadwal,
    color: AppColors.primary,
  ),
  _QuickAction(
    label: 'Nilai Siswa',
    icon: Icons.grade,
    route: AppRoutes.nilai,
    color: AppColors.success,
  ),
  _QuickAction(
    label: 'Absen Harian',
    icon: Icons.how_to_reg,
    route: AppRoutes.absensi,
    color: AppColors.info,
  ),
  _QuickAction(
    label: 'Tugas',
    icon: Icons.assignment,
    route: AppRoutes.tugas,
    color: AppColors.secondary,
  ),
];

const _siswaActions = [
  _QuickAction(
    label: 'Jadwal Pelajaran',
    icon: Icons.calendar_today,
    route: AppRoutes.jadwal,
    color: AppColors.primary,
  ),
  _QuickAction(
    label: 'Nilai Saya',
    icon: Icons.grade,
    route: AppRoutes.nilai,
    color: AppColors.success,
  ),
  _QuickAction(
    label: 'Absen Harian',
    icon: Icons.how_to_reg,
    route: AppRoutes.absensi,
    color: AppColors.info,
  ),
  _QuickAction(
    label: 'Tugas',
    icon: Icons.assignment,
    route: AppRoutes.tugas,
    color: AppColors.secondary,
  ),
  _QuickAction(
    label: 'Rapor',
    icon: Icons.book,
    route: AppRoutes.rapor,
    color: AppColors.accent,
  ),
];

const _waliActions = [
  _QuickAction(
    label: 'Absensi Anak',
    icon: Icons.checklist,
    route: AppRoutes.absensi,
    color: AppColors.info,
  ),
  _QuickAction(
    label: 'Nilai Anak',
    icon: Icons.grade,
    route: AppRoutes.nilai,
    color: AppColors.success,
  ),
  _QuickAction(
    label: 'Jadwal',
    icon: Icons.calendar_today,
    route: AppRoutes.jadwal,
    color: AppColors.primary,
  ),
];

const _actionsByRole = {
  'admin': _adminActions,
  'guru': _guruActions,
  'siswa': _siswaActions,
  'wali': _waliActions,
};

class DashboardQuickActions extends StatelessWidget {
  final String role;

  const DashboardQuickActions({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    final actions = _actionsByRole[role] ?? _adminActions;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.95,
              ),
              itemCount: actions.length,
              itemBuilder: (context, i) {
                final action = actions[i];
                return InkWell(
                  onTap: () => context.go(action.route),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.divider),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: action.color.withAlpha(30),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            action.icon,
                            color: action.color,
                            size: 20,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          action.label,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                fontWeight: FontWeight.w500,
                                fontSize: 11,
                              ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
