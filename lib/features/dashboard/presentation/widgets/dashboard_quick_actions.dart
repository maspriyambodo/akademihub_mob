import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_section_header.dart';
import '../../../../core/widgets/app_surface_card.dart';

class _QuickAction {
  final String label;
  final IconData icon;
  final String route;
  final Color tintColor;
  final Color iconColor;

  const _QuickAction({
    required this.label,
    required this.icon,
    required this.route,
    required this.tintColor,
    required this.iconColor,
  });
}

_QuickAction _action({
  required String label,
  required IconData icon,
  required String route,
}) {
  // Meaningful category color palette by route
  final (tint, color) = switch (route) {
    AppRoutes.materi ||
    AppRoutes.jadwal ||
    AppRoutes.ujian ||
    AppRoutes.perpustakaan => (
      AppColors.role('siswa').container,
      AppColors.role('siswa').onContainer,
    ),
    AppRoutes.absensi => (
      AppColors.semantic(AppStatusTone.success).container,
      AppColors.semantic(AppStatusTone.success).onContainer,
    ),
    AppRoutes.forum ||
    AppRoutes.notifications ||
    AppRoutes.organisasi => (AppColors.primaryLight, AppColors.primaryDark),
    AppRoutes.keuangan ||
    AppRoutes.tugas ||
    AppRoutes.rapor ||
    AppRoutes.tmb ||
    AppRoutes.kalender => (
      AppColors.semantic(AppStatusTone.warning).container,
      AppColors.semantic(AppStatusTone.warning).onContainer,
    ),
    AppRoutes.bk || AppRoutes.ews => (
      AppColors.semantic(AppStatusTone.error).container,
      AppColors.semantic(AppStatusTone.error).onContainer,
    ),
    _ => (AppColors.paperMuted, AppColors.inkSoft),
  };

  return _QuickAction(
    label: label,
    icon: icon,
    route: route,
    tintColor: tint,
    iconColor: color,
  );
}

final _adminActions = [
  _action(
    label: 'Perpustakaan',
    icon: Icons.local_library_outlined,
    route: AppRoutes.perpustakaan,
  ),
  _action(
    label: 'Absensi',
    icon: Icons.checklist_outlined,
    route: AppRoutes.absensi,
  ),
  _action(label: 'Nilai', icon: Icons.grade_outlined, route: AppRoutes.nilai),
  _action(
    label: 'Jadwal',
    icon: Icons.calendar_today_outlined,
    route: AppRoutes.jadwal,
  ),
  _action(
    label: 'Tugas',
    icon: Icons.assignment_outlined,
    route: AppRoutes.tugas,
  ),
  _action(
    label: 'Rapor',
    icon: Icons.auto_stories_outlined,
    route: AppRoutes.rapor,
  ),
  _action(
    label: 'Notifikasi',
    icon: Icons.notifications_outlined,
    route: AppRoutes.notifications,
  ),
  _action(
    label: 'Pembayaran SPP',
    icon: Icons.payments_outlined,
    route: AppRoutes.keuangan,
  ),
  _action(
    label: 'Materi',
    icon: Icons.menu_book_outlined,
    route: AppRoutes.materi,
  ),
  _action(label: 'Forum', icon: Icons.forum_outlined, route: AppRoutes.forum),
  _action(
    label: 'Ekstrakurikuler',
    icon: Icons.sports_soccer_outlined,
    route: AppRoutes.ekstrakurikuler,
  ),
  _action(
    label: 'Kalender',
    icon: Icons.event_note_outlined,
    route: AppRoutes.kalender,
  ),
  _action(
    label: 'Ujian & Ranking',
    icon: Icons.emoji_events_outlined,
    route: AppRoutes.ujian,
  ),
  _action(
    label: 'Tes Minat Bakat',
    icon: Icons.psychology_outlined,
    route: AppRoutes.tmb,
  ),
  _action(label: 'BK', icon: Icons.support_agent_outlined, route: AppRoutes.bk),
  _action(
    label: 'EWS',
    icon: Icons.warning_amber_rounded,
    route: AppRoutes.ews,
  ),
  _action(
    label: 'Profil',
    icon: Icons.account_circle_outlined,
    route: AppRoutes.profil,
  ),
];

final _guruActions = [
  _action(
    label: 'Perpustakaan',
    icon: Icons.local_library_outlined,
    route: AppRoutes.perpustakaan,
  ),
  _action(
    label: 'Absensi',
    icon: Icons.checklist_outlined,
    route: AppRoutes.absensi,
  ),
  _action(label: 'Nilai', icon: Icons.grade_outlined, route: AppRoutes.nilai),
  _action(
    label: 'Jadwal',
    icon: Icons.calendar_today_outlined,
    route: AppRoutes.jadwal,
  ),
  _action(
    label: 'Tugas',
    icon: Icons.assignment_outlined,
    route: AppRoutes.tugas,
  ),
  _action(
    label: 'Rapor',
    icon: Icons.auto_stories_outlined,
    route: AppRoutes.rapor,
  ),
  _action(
    label: 'Notifikasi',
    icon: Icons.notifications_outlined,
    route: AppRoutes.notifications,
  ),
  _action(
    label: 'Materi',
    icon: Icons.menu_book_outlined,
    route: AppRoutes.materi,
  ),
  _action(label: 'Forum', icon: Icons.forum_outlined, route: AppRoutes.forum),
  _action(
    label: 'Ekstrakurikuler',
    icon: Icons.sports_soccer_outlined,
    route: AppRoutes.ekstrakurikuler,
  ),
  _action(
    label: 'Ujian',
    icon: Icons.assignment_turned_in_outlined,
    route: AppRoutes.ujian,
  ),
  _action(label: 'BK', icon: Icons.support_agent_outlined, route: AppRoutes.bk),
  _action(
    label: 'EWS',
    icon: Icons.warning_amber_rounded,
    route: AppRoutes.ews,
  ),
  _action(
    label: 'Profil',
    icon: Icons.account_circle_outlined,
    route: AppRoutes.profil,
  ),
];

final _siswaActions = [
  _action(
    label: 'Perpustakaan',
    icon: Icons.local_library_outlined,
    route: AppRoutes.perpustakaan,
  ),
  _action(
    label: 'Absensi',
    icon: Icons.checklist_outlined,
    route: AppRoutes.absensi,
  ),
  _action(label: 'Nilai', icon: Icons.grade_outlined, route: AppRoutes.nilai),
  _action(
    label: 'Jadwal',
    icon: Icons.calendar_today_outlined,
    route: AppRoutes.jadwal,
  ),
  _action(
    label: 'Tugas',
    icon: Icons.assignment_outlined,
    route: AppRoutes.tugas,
  ),
  _action(
    label: 'Rapor',
    icon: Icons.auto_stories_outlined,
    route: AppRoutes.rapor,
  ),
  _action(
    label: 'Notifikasi',
    icon: Icons.notifications_outlined,
    route: AppRoutes.notifications,
  ),
  _action(
    label: 'Pembayaran SPP',
    icon: Icons.payments_outlined,
    route: AppRoutes.keuangan,
  ),
  _action(
    label: 'Materi',
    icon: Icons.menu_book_outlined,
    route: AppRoutes.materi,
  ),
  _action(label: 'Forum', icon: Icons.forum_outlined, route: AppRoutes.forum),
  _action(
    label: 'Ekstrakurikuler',
    icon: Icons.sports_soccer_outlined,
    route: AppRoutes.ekstrakurikuler,
  ),
  _action(
    label: 'Ujian',
    icon: Icons.assignment_turned_in_outlined,
    route: AppRoutes.ujian,
  ),
  _action(
    label: 'Tes Minat Bakat',
    icon: Icons.psychology_outlined,
    route: AppRoutes.tmb,
  ),
  _action(
    label: 'Profil',
    icon: Icons.account_circle_outlined,
    route: AppRoutes.profil,
  ),
];

final _waliActions = [
  _action(
    label: 'Absensi Anak',
    icon: Icons.checklist_outlined,
    route: AppRoutes.absensi,
  ),
  _action(
    label: 'Nilai Anak',
    icon: Icons.grade_outlined,
    route: AppRoutes.nilai,
  ),
  _action(
    label: 'Jadwal Anak',
    icon: Icons.calendar_today_outlined,
    route: AppRoutes.jadwal,
  ),
  _action(
    label: 'Tugas Anak',
    icon: Icons.assignment_outlined,
    route: AppRoutes.tugas,
  ),
  _action(
    label: 'Rapor Anak',
    icon: Icons.auto_stories_outlined,
    route: AppRoutes.rapor,
  ),
  _action(
    label: 'Notifikasi',
    icon: Icons.notifications_outlined,
    route: AppRoutes.notifications,
  ),
  _action(
    label: 'Pembayaran SPP',
    icon: Icons.payments_outlined,
    route: AppRoutes.keuangan,
  ),
  _action(label: 'Forum', icon: Icons.forum_outlined, route: AppRoutes.forum),
  _action(
    label: 'Profil',
    icon: Icons.account_circle_outlined,
    route: AppRoutes.profil,
  ),
];

class DashboardQuickActions extends StatefulWidget {
  final String role;
  final List<String> permissions;
  final bool hasChild;

  const DashboardQuickActions({
    super.key,
    required this.role,
    required this.permissions,
    this.hasChild = true,
  });

  @override
  State<DashboardQuickActions> createState() => _DashboardQuickActionsState();
}

class _DashboardQuickActionsState extends State<DashboardQuickActions> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final rawActions = switch (widget.role) {
      'guru' => _guruActions,
      'siswa' => _siswaActions,
      'wali' => _waliActions,
      _ => _adminActions,
    };

    final actions = rawActions.where((action) {
      if (widget.role == 'wali' &&
          !widget.hasChild &&
          action.route != AppRoutes.notifications &&
          action.route != AppRoutes.profil) {
        return false;
      }
      return AppRoutes.canAccess(
        action.route,
        authenticated: true,
        permissions: widget.permissions,
      );
    }).toList();

    final visibleActions = _showAll ? actions : actions.take(8).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(
          title: 'Layanan & Akses Cepat',
          eyebrow: 'Fitur',
          actionLabel: actions.length > 8
              ? (_showAll ? 'Tampilkan Ringkas' : 'Lihat Semua')
              : null,
          onAction: actions.length > 8
              ? () => setState(() => _showAll = !_showAll)
              : null,
        ),
        const SizedBox(height: AppSpacing.sm),
        AppSurfaceCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth < 360
                  ? 3
                  : constraints.maxWidth < 600
                  ? 4
                  : 6;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: AppSpacing.sm,
                  crossAxisSpacing: AppSpacing.xs,
                  mainAxisExtent: 84,
                ),
                itemCount: visibleActions.length,
                itemBuilder: (context, index) {
                  final item = visibleActions[index];

                  return InkWell(
                    onTap: () => context.push(item.route),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: item.tintColor,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                            child: Icon(
                              item.icon,
                              color: item.iconColor,
                              size: 22,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.inkSoft,
                              height: 1.2,
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
              );
            },
          ),
        ),
      ],
    );
  }
}
