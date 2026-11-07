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
  // Vibrant, intentional SaaS color taxonomy by feature route
  final (tint, color) = switch (route) {
    AppRoutes.perpustakaan => (const Color(0xFFEEF2FF), const Color(0xFF4F46E5)),
    AppRoutes.absensi => (const Color(0xFFD1FAE5), const Color(0xFF059669)),
    AppRoutes.nilai => (const Color(0xFFFEF3C7), const Color(0xFFD97706)),
    AppRoutes.jadwal => (const Color(0xFFE0F2FE), const Color(0xFF0284C7)),
    AppRoutes.tugas => (const Color(0xFFF3E8FF), const Color(0xFF7C3AED)),
    AppRoutes.rapor => (const Color(0xFFFFE4E6), const Color(0xFFE11D48)),
    AppRoutes.keuangan => (const Color(0xFFCCFBF1), const Color(0xFF0D9488)),
    AppRoutes.materi => (const Color(0xFFCFFAFE), const Color(0xFF0891B2)),
    AppRoutes.ujian => (const Color(0xFFEDE9FE), const Color(0xFF6D28D9)),
    AppRoutes.tmb => (const Color(0xFFFCE7F3), const Color(0xFFBE185D)),
    AppRoutes.notifications => (const Color(0xFFDBEAFE), const Color(0xFF2563EB)),
    AppRoutes.forum => (const Color(0xFFFFEDD5), const Color(0xFFEA580C)),
    AppRoutes.ekstrakurikuler => (const Color(0xFFECFCCB), const Color(0xFF65A30D)),
    AppRoutes.kalender => (const Color(0xFFF1F5F9), const Color(0xFF475569)),
    AppRoutes.bk => (const Color(0xFFFFE4E6), const Color(0xFFE11D48)),
    AppRoutes.ews => (const Color(0xFFFEE2E2), const Color(0xFFDC2626)),
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
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.md),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth < 320
                  ? 3
                  : constraints.maxWidth < 600
                  ? 4
                  : 6;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: AppSpacing.md,
                  crossAxisSpacing: AppSpacing.xs,
                  mainAxisExtent: 90,
                ),
                itemCount: visibleActions.length,
                itemBuilder: (context, index) {
                  final item = visibleActions[index];

                  return InkWell(
                    onTap: () => context.push(item.route),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    splashColor: item.iconColor.withValues(alpha: 0.15),
                    highlightColor: Colors.transparent,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  item.tintColor,
                                  Color.alphaBlend(
                                    item.iconColor.withValues(alpha: 0.12),
                                    item.tintColor,
                                  ),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: item.iconColor.withValues(alpha: 0.22),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: item.iconColor.withValues(alpha: 0.10),
                                  offset: const Offset(0, 3),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Icon(
                              item.icon,
                              color: item.iconColor,
                              size: 22,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item.label,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink,
                              letterSpacing: -0.2,
                              height: 1.15,
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
