import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../router/app_router.dart';
import '../utils/responsive.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';

class MainShell extends StatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final _tabs = const [
    _TabItem(
      icon: Icons.dashboard_outlined,
      label: 'Dashboard',
      route: AppRoutes.dashboard,
    ),
    _TabItem(
      icon: Icons.how_to_reg_outlined,
      label: 'Absensi',
      route: AppRoutes.absensi,
    ),
    _TabItem(
      icon: Icons.schedule_outlined,
      label: 'Jadwal',
      route: AppRoutes.jadwal,
    ),
    _TabItem(
      icon: Icons.grade_outlined,
      label: 'Nilai',
      route: AppRoutes.nilai,
    ),
    _TabItem(
      icon: Icons.assignment_outlined,
      label: 'Tugas',
      route: AppRoutes.tugas,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          context.go(AppRoutes.login);
        }
      },
      builder: (context, state) {
        final permissions = state is AuthAuthenticated
            ? state.user.permissions
            : const <String>[];
        final tabs = _tabs.where((tab) {
          final required = AppRoutes.permissionsFor(tab.route);
          return required.isEmpty || required.any(permissions.contains);
        }).toList();
        final location = GoRouterState.of(context).uri.path;
        final currentIndex = tabs.indexWhere((tab) => tab.route == location);
        final selectedIndex = currentIndex < 0 ? 0 : currentIndex;
        void goTo(int index) => context.go(tabs[index].route);

        return LayoutBuilder(
          builder: (context, constraints) {
            // Layout berdasarkan ruang jendela, bukan tipe perangkat.
            final lebar = constraints.maxWidth;
            final useRail = lebar > Responsive.expandedWidth;

            if (useRail) {
              return Scaffold(
                body: Row(
                  children: [
                    NavigationRail(
                      selectedIndex: selectedIndex,
                      onDestinationSelected: goTo,
                      labelType: NavigationRailLabelType.all,
                      destinations: tabs
                          .map(
                            (t) => NavigationRailDestination(
                              icon: Icon(t.icon),
                              label: Text(t.label),
                            ),
                          )
                          .toList(),
                    ),
                    const VerticalDivider(width: 1, thickness: 1),
                    Expanded(child: widget.child),
                  ],
                ),
              );
            }

            return Scaffold(
              body: widget.child,
              bottomNavigationBar: BottomNavigationBar(
                currentIndex: selectedIndex,
                type: BottomNavigationBarType.fixed,
                showSelectedLabels: true,
                showUnselectedLabels: true,
                selectedFontSize: 11,
                unselectedFontSize: 10.5,
                onTap: goTo,
                items: tabs
                    .map(
                      (t) => BottomNavigationBarItem(
                        icon: Icon(t.icon),
                        label: t.label,
                      ),
                    )
                    .toList(),
              ),
            );
          },
        );
      },
    );
  }
}

class _TabItem {
  final IconData icon;
  final String label;
  final String route;
  const _TabItem({
    required this.icon,
    required this.label,
    required this.route,
  });
}
