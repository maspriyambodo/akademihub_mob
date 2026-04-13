import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../router/app_router.dart';
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

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          context.go(AppRoutes.login);
        }
      },
      child: Scaffold(
        body: widget.child,
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() => _currentIndex = index);
            context.go(_tabs[index].route);
          },
          items: _tabs
              .map(
                (t) =>
                    BottomNavigationBarItem(icon: Icon(t.icon), label: t.label),
              )
              .toList(),
        ),
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
