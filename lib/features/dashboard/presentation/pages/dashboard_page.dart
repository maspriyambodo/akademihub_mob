import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../../core/router/app_router.dart';
import 'package:go_router/go_router.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = (context.watch<AuthBloc>().state as AuthAuthenticated?)?.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AkademiHub'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push(AppRoutes.notifications),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () =>
                context.read<AuthBloc>().add(AuthLogoutRequested()),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {},
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Greeting card
            _buildGreetingCard(context, user?.name ?? ''),
            const SizedBox(height: 20),

            // Quick access grid
            Text('Menu Utama', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _buildMenuGrid(context, user?.primaryRole ?? ''),
          ],
        ),
      ),
    );
  }

  Widget _buildGreetingCard(BuildContext context, String name) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selamat datang,',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Icon(Icons.calendar_today, color: Colors.white70, size: 14),
              SizedBox(width: 6),
              Text(
                'Tahun Ajaran 2025/2026',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuGrid(BuildContext context, String role) {
    final menus = _getMenusForRole(role);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemCount: menus.length,
      itemBuilder: (context, i) => _MenuCard(item: menus[i]),
    );
  }

  List<_MenuItem> _getMenusForRole(String role) => [
    _MenuItem(
      icon: Icons.how_to_reg,
      label: 'Absensi',
      route: AppRoutes.absensi,
      color: AppColors.success,
    ),
    _MenuItem(
      icon: Icons.schedule,
      label: 'Jadwal',
      route: AppRoutes.jadwal,
      color: AppColors.primary,
    ),
    _MenuItem(
      icon: Icons.grade,
      label: 'Nilai',
      route: AppRoutes.nilai,
      color: AppColors.warning,
    ),
    _MenuItem(
      icon: Icons.assignment,
      label: 'Tugas',
      route: AppRoutes.tugas,
      color: AppColors.secondary,
    ),
    _MenuItem(
      icon: Icons.book,
      label: 'Rapor',
      route: AppRoutes.rapor,
      color: AppColors.accent,
    ),
    _MenuItem(
      icon: Icons.notifications,
      label: 'Notifikasi',
      route: AppRoutes.notifications,
      color: AppColors.info,
    ),
  ];
}

class _MenuItem {
  final IconData icon;
  final String label;
  final String route;
  final Color color;
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.color,
  });
}

class _MenuCard extends StatelessWidget {
  final _MenuItem item;
  const _MenuCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go(item.route),
      borderRadius: BorderRadius.circular(12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: item.color.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(item.icon, color: item.color, size: 26),
              ),
              const SizedBox(height: 8),
              Text(
                item.label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
