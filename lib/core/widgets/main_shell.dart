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
  int _currentIndex = 0;

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

  void _goTo(int index) {
    setState(() => _currentIndex = index);
    context.go(_tabs[index].route);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          context.go(AppRoutes.login);
        }
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Layout berdasarkan ruang jendela, bukan tipe perangkat.
          final lebar = constraints.maxWidth;
          final useRail = lebar > Responsive.expandedWidth;

          if (useRail) {
            return Scaffold(
              body: Row(
                children: [
                  NavigationRail(
                    selectedIndex: _currentIndex,
                    onDestinationSelected: _goTo,
                    labelType: NavigationRailLabelType.all,
                    destinations: _tabs
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
              currentIndex: _currentIndex,
              type: BottomNavigationBarType.fixed,
              showSelectedLabels: true,
              showUnselectedLabels: true,
              selectedFontSize: 11,
              unselectedFontSize: 10.5,
              onTap: _goTo,
              items: _tabs
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
      ),
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
