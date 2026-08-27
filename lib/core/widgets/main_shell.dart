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
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      label: 'Beranda',
      route: AppRoutes.dashboard,
    ),
    _TabItem(
      icon: Icons.how_to_reg_outlined,
      selectedIcon: Icons.how_to_reg_rounded,
      label: 'Absensi',
      route: AppRoutes.absensi,
    ),
    _TabItem(
      icon: Icons.schedule_outlined,
      selectedIcon: Icons.schedule_rounded,
      label: 'Jadwal',
      route: AppRoutes.jadwal,
    ),
    _TabItem(
      icon: Icons.assignment_outlined,
      selectedIcon: Icons.assignment_rounded,
      label: 'Tugas',
      route: AppRoutes.tugas,
    ),
    _TabItem(
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
      label: 'Profil',
      route: AppRoutes.profil,
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
        if (state is! AuthAuthenticated) return const SizedBox.shrink();
        final tabs = _tabs.where((tab) {
          return AppRoutes.canAccess(
            tab.route,
            authenticated: true,
            permissions: state.user.permissions,
          );
        }).toList();
        final location = GoRouterState.of(context).uri.path;
        final currentIndex = tabs.indexWhere(
          (tab) =>
              location == tab.route || location.startsWith('${tab.route}/'),
        );
        final selectedIndex = currentIndex < 0 ? tabs.length - 1 : currentIndex;
        void goTo(int index) => context.go(tabs[index].route);

        return LayoutBuilder(
          builder: (context, constraints) {
            // Layout berdasarkan ruang jendela, bukan tipe perangkat.
            final lebar = constraints.maxWidth;
            final useRail = lebar >= Responsive.expandedWidth;

            if (useRail) {
              return Scaffold(
                body: Row(
                  children: [
                    NavigationRail(
                      selectedIndex: selectedIndex,
                      onDestinationSelected: goTo,
                      labelType: NavigationRailLabelType.all,
                      leading: Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Semantics(
                          label: 'AkademiHub',
                          child: const CircleAvatar(
                            radius: 22,
                            child: Icon(Icons.auto_stories_rounded),
                          ),
                        ),
                      ),
                      destinations: tabs
                          .map(
                            (t) => NavigationRailDestination(
                              icon: Icon(t.icon),
                              selectedIcon: Icon(t.selectedIcon),
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
              bottomNavigationBar: NavigationBar(
                selectedIndex: selectedIndex,
                onDestinationSelected: goTo,
                destinations: tabs
                    .map(
                      (t) => NavigationDestination(
                        icon: Icon(t.icon),
                        selectedIcon: Icon(t.selectedIcon),
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
  final IconData selectedIcon;
  final String label;
  final String route;
  const _TabItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.route,
  });
}
