import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';

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
  _QuickAction(
    label: 'Pembayaran SPP',
    icon: Icons.payments_outlined,
    route: AppRoutes.keuangan,
    color: AppColors.success,
  ),
  _QuickAction(
    label: 'Materi',
    icon: Icons.menu_book_outlined,
    route: AppRoutes.materi,
    color: AppColors.info,
  ),
  _QuickAction(
    label: 'Forum',
    icon: Icons.forum_outlined,
    route: AppRoutes.forum,
    color: AppColors.secondary,
  ),
  _QuickAction(
    label: 'Ekstrakurikuler',
    icon: Icons.sports_soccer,
    route: AppRoutes.ekstrakurikuler,
    color: AppColors.primaryLight,
  ),
  // Kalender hanya untuk admin: di RbacSeeder, izin `kalender-akademik.view`
  // hanya diberikan lewat bundle $sysAdmin yang dipakai role `admin` saja.
  // Role lain akan menerima 403.
  _QuickAction(
    label: 'Kalender',
    icon: Icons.event_note,
    route: AppRoutes.kalender,
    color: AppColors.waliColor,
  ),
  _QuickAction(
    label: 'Ujian & Ranking',
    icon: Icons.emoji_events_outlined,
    route: AppRoutes.ujian,
    color: AppColors.warning,
  ),
  _QuickAction(
    label: 'Tes Minat Bakat',
    icon: Icons.psychology_outlined,
    route: AppRoutes.tmb,
    color: AppColors.secondary,
  ),
  _QuickAction(
    label: 'BK',
    icon: Icons.support_agent,
    route: AppRoutes.bk,
    color: AppColors.guruColor,
  ),
  _QuickAction(
    label: 'PPDB',
    icon: Icons.how_to_reg_outlined,
    route: AppRoutes.ppdb,
    color: AppColors.info,
  ),
  _QuickAction(
    label: 'EWS',
    icon: Icons.warning_amber,
    route: AppRoutes.ews,
    color: AppColors.error,
  ),
  _QuickAction(
    label: 'Profil',
    icon: Icons.account_circle_outlined,
    route: AppRoutes.profil,
    color: AppColors.textSecondary,
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
    label: 'Riwayat Absensi',
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
  _QuickAction(
    label: 'Notifikasi',
    icon: Icons.notifications,
    route: AppRoutes.notifications,
    color: AppColors.warning,
  ),
  _QuickAction(
    label: 'Materi',
    icon: Icons.menu_book_outlined,
    route: AppRoutes.materi,
    color: AppColors.info,
  ),
  _QuickAction(
    label: 'Forum',
    icon: Icons.forum_outlined,
    route: AppRoutes.forum,
    color: AppColors.secondary,
  ),
  _QuickAction(
    label: 'Ekstrakurikuler',
    icon: Icons.sports_soccer,
    route: AppRoutes.ekstrakurikuler,
    color: AppColors.primaryLight,
  ),
  _QuickAction(
    label: 'Ujian & Ranking',
    icon: Icons.emoji_events_outlined,
    route: AppRoutes.ujian,
    color: AppColors.warning,
  ),
  // BK relevan untuk guru BK (dinormalisasi ke role guru); guru biasa tanpa
  // izin `bk-kasus.view` melihat layar akses ditolak yang menjelaskan.
  _QuickAction(
    label: 'BK',
    icon: Icons.support_agent,
    route: AppRoutes.bk,
    color: AppColors.guruColor,
  ),
  _QuickAction(
    label: 'Profil',
    icon: Icons.account_circle_outlined,
    route: AppRoutes.profil,
    color: AppColors.textSecondary,
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
  _QuickAction(
    label: 'Notifikasi',
    icon: Icons.notifications,
    route: AppRoutes.notifications,
    color: AppColors.warning,
  ),
  _QuickAction(
    label: 'SPP & Tagihan',
    icon: Icons.account_balance_wallet_outlined,
    route: AppRoutes.keuangan,
    color: AppColors.success,
  ),
  _QuickAction(
    label: 'Materi',
    icon: Icons.menu_book_outlined,
    route: AppRoutes.materi,
    color: AppColors.info,
  ),
  _QuickAction(
    label: 'Forum',
    icon: Icons.forum_outlined,
    route: AppRoutes.forum,
    color: AppColors.secondary,
  ),
  _QuickAction(
    label: 'Ekstrakurikuler',
    icon: Icons.sports_soccer,
    route: AppRoutes.ekstrakurikuler,
    color: AppColors.primaryLight,
  ),
  _QuickAction(
    label: 'Ujian & Ranking',
    icon: Icons.emoji_events_outlined,
    route: AppRoutes.ujian,
    color: AppColors.warning,
  ),
  _QuickAction(
    label: 'BK',
    icon: Icons.support_agent,
    route: AppRoutes.bk,
    color: AppColors.guruColor,
  ),
  _QuickAction(
    label: 'EWS',
    icon: Icons.warning_amber,
    route: AppRoutes.ews,
    color: AppColors.error,
  ),
  _QuickAction(
    label: 'Profil',
    icon: Icons.account_circle_outlined,
    route: AppRoutes.profil,
    color: AppColors.textSecondary,
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
  _QuickAction(
    label: 'Tugas Anak',
    icon: Icons.assignment,
    route: AppRoutes.tugas,
    color: AppColors.secondary,
  ),
  _QuickAction(
    label: 'Rapor Anak',
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
  _QuickAction(
    label: 'SPP & Tagihan',
    icon: Icons.account_balance_wallet_outlined,
    route: AppRoutes.keuangan,
    color: AppColors.success,
  ),
  _QuickAction(
    label: 'Materi',
    icon: Icons.menu_book_outlined,
    route: AppRoutes.materi,
    color: AppColors.info,
  ),
  _QuickAction(
    label: 'Forum',
    icon: Icons.forum_outlined,
    route: AppRoutes.forum,
    color: AppColors.secondary,
  ),
  _QuickAction(
    label: 'Ekstrakurikuler',
    icon: Icons.sports_soccer,
    route: AppRoutes.ekstrakurikuler,
    color: AppColors.primaryLight,
  ),
  _QuickAction(
    label: 'EWS',
    icon: Icons.warning_amber,
    route: AppRoutes.ews,
    color: AppColors.error,
  ),
  _QuickAction(
    label: 'Profil',
    icon: Icons.account_circle_outlined,
    route: AppRoutes.profil,
    color: AppColors.textSecondary,
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
  final List<String> permissions;
  final bool hasChild;

  const DashboardQuickActions({
    super.key,
    required this.role,
    required this.permissions,
    this.hasChild = true,
  });

  @override
  Widget build(BuildContext context) {
    final actions = (_actionsByRole[role] ?? _adminActions).where((action) {
      if (role == 'wali' && !hasChild && action.route != AppRoutes.profil) {
        return false;
      }
      final required = switch (action.route) {
        AppRoutes.ews => const ['ews.view'],
        AppRoutes.bk => const ['bk-kasus.view'],
        AppRoutes.kalender => const ['kalender-akademik.view'],
        AppRoutes.ppdb => const [
          'ppdb.pendaftaran.view',
          'ppdb.gelombang.view',
        ],
        AppRoutes.ujian => const ['ujian.view', 'ranking.view'],
        AppRoutes.tmb => const [
          'tes-minat-bakat.view',
          'tes-minat-bakat-peserta.view',
        ],
        _ => const <String>[],
      };
      return required.isEmpty || required.any(permissions.contains);
    }).toList();

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
              // Lebar maks per sel menentukan jumlah kolom (3 di HP umum,
              // 2 di layar sempit, lebih banyak di tablet); tinggi absolut
              // mencegah ikon+label meluber saat sel menyempit.
              gridDelegate: Responsive.gridDelegate(
                context,
                lebarMaks: 120,
                tinggi: 96,
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
