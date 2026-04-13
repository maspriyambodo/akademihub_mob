import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../di/injection.dart';
import '../widgets/main_shell.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/absensi/presentation/pages/absensi_page.dart';
import '../../features/jadwal/presentation/pages/jadwal_page.dart';
import '../../features/nilai/presentation/pages/nilai_page.dart';
import '../../features/tugas/presentation/pages/tugas_page.dart';
import '../../features/rapor/presentation/pages/rapor_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String absensi = '/absensi';
  static const String jadwal = '/jadwal';
  static const String nilai = '/nilai';
  static const String tugas = '/tugas';
  static const String rapor = '/rapor';
  static const String notifications = '/notifications';
}

final router = GoRouter(
  initialLocation: AppRoutes.splash,
  redirect: (context, state) {
    final authState = context.read<AuthBloc>().state;
    final path = state.uri.path;

    // Tunggu hasil auth check — tetap di splash
    if (authState is AuthInitial || authState is AuthLoading) {
      if (path != AppRoutes.splash) return AppRoutes.splash;
      return null;
    }

    // Belum login → ke halaman login
    if (authState is AuthUnauthenticated || authState is AuthError) {
      if (path != AppRoutes.login) return AppRoutes.login;
      return null;
    }

    // Sudah login → ke dashboard (jika masih di splash/login)
    if (authState is AuthAuthenticated) {
      if (path == AppRoutes.splash || path == AppRoutes.login) {
        return AppRoutes.dashboard;
      }
    }

    return null;
  },
  refreshListenable: _RouterNotifier(),
  routes: [
    GoRoute(path: AppRoutes.splash, builder: (_, _) => const _SplashPage()),
    GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginPage()),
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: AppRoutes.dashboard,
          builder: (_, _) => const DashboardPage(),
        ),
        GoRoute(
          path: AppRoutes.absensi,
          builder: (_, _) => const AbsensiPage(),
        ),
        GoRoute(path: AppRoutes.jadwal, builder: (_, _) => const JadwalPage()),
        GoRoute(path: AppRoutes.nilai, builder: (_, _) => const NilaiPage()),
        GoRoute(path: AppRoutes.tugas, builder: (_, _) => const TugasPage()),
        GoRoute(path: AppRoutes.rapor, builder: (_, _) => const RaporPage()),
        GoRoute(
          path: AppRoutes.notifications,
          builder: (_, _) => const NotificationsPage(),
        ),
      ],
    ),
  ],
);

/// Splash: restore tenant dari storage → langsung cek auth
class _SplashPage extends StatefulWidget {
  const _SplashPage();

  @override
  State<_SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<_SplashPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Cek apakah token masih valid
      context.read<AuthBloc>().add(AuthCheckRequested());
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

/// Notifies GoRouter to re-evaluate redirects when AuthBloc emits.
class _RouterNotifier extends ChangeNotifier {
  late final StreamSubscription<dynamic> _authSub;

  _RouterNotifier() {
    _authSub = sl<AuthBloc>().stream.listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _authSub.cancel();
    super.dispose();
  }
}
