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
import '../../features/keuangan/presentation/pages/keuangan_page.dart';
import '../../features/profil/presentation/pages/profil_page.dart';
import '../../features/materi/presentation/pages/materi_page.dart';
import '../../features/forum/presentation/pages/forum_page.dart';
import '../../features/ekstrakurikuler/presentation/pages/ekstrakurikuler_page.dart';
import '../../features/kalender/presentation/pages/kalender_page.dart';
import '../../features/bk/presentation/pages/bk_page.dart';
import '../../features/ujian/presentation/pages/ujian_page.dart';
import '../../features/tmb/presentation/pages/tmb_page.dart';
import '../../features/ppdb/presentation/pages/ppdb_page.dart';
import '../../features/ppdb/presentation/pages/ppdb_public_page.dart';
import '../../features/ews/presentation/pages/ews_page.dart';
import '../../features/siswa_insight/presentation/pages/siswa_insight_page.dart';

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
  static const String keuangan = '/keuangan';
  static const String profil = '/profil';
  static const String materi = '/materi';
  static const String forum = '/forum';
  static const String ekstrakurikuler = '/ekstrakurikuler';
  static const String kalender = '/kalender';
  static const String bk = '/bk';
  static const String ujian = '/ujian';
  static const String tmb = '/tmb';
  static const String ppdb = '/ppdb';
  static const String ppdbPublic = '/ppdb/portal';
  static const String ews = '/ews';
  static const List<String> ewsAliases = [
    '/early-warning',
    '/early-warning-system',
  ];
  static const String siswaInsight = '/siswa/:id/insight';

  static List<String> permissionsFor(String path) => switch (path) {
    absensi => const ['absensi-siswa.view', 'absensi-guru.view'],
    jadwal => const ['jadwal-pelajaran.view'],
    nilai => const ['nilai.view'],
    tugas => const ['tugas.view', 'tugas-siswa.view'],
    kalender => const ['kalender-akademik.view'],
    bk => const ['bk-kasus.view'],
    ujian => const ['ujian.view', 'ranking.view'],
    tmb => const ['tes-minat-bakat.view', 'tes-minat-bakat-peserta.view'],
    ppdb => const ['ppdb.pendaftaran.view', 'ppdb.gelombang.view'],
    ews => const ['ews.view'],
    _ => const [],
  };
}

final router = GoRouter(
  initialLocation: AppRoutes.splash,
  redirect: (context, state) {
    final authState = context.read<AuthBloc>().state;
    final path = state.uri.path;

    if (path == AppRoutes.ppdbPublic) return null;

    // Initial hanya terjadi saat bootstrap. Loading login harus tetap di login.
    if (authState is AuthInitial) {
      if (path != AppRoutes.splash) return AppRoutes.splash;
      return null;
    }

    if (authState is AuthLoading) return null;

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
      final required = AppRoutes.permissionsFor(path);
      if (required.isNotEmpty &&
          !required.any(authState.user.permissions.contains)) {
        return AppRoutes.dashboard;
      }
    }

    return null;
  },
  refreshListenable: _RouterNotifier(),
  routes: [
    GoRoute(path: AppRoutes.splash, builder: (_, _) => const _SplashPage()),
    GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginPage()),
    GoRoute(
      path: AppRoutes.ppdbPublic,
      builder: (_, _) => const PpdbPublicPage(),
    ),
    for (final alias in AppRoutes.ewsAliases)
      GoRoute(path: alias, redirect: (_, _) => AppRoutes.ews),
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
        GoRoute(
          path: AppRoutes.keuangan,
          builder: (_, _) => const KeuanganPage(),
        ),
        GoRoute(path: AppRoutes.profil, builder: (_, _) => const ProfilPage()),
        GoRoute(path: AppRoutes.materi, builder: (_, _) => const MateriPage()),
        GoRoute(path: AppRoutes.forum, builder: (_, _) => const ForumPage()),
        GoRoute(
          path: AppRoutes.ekstrakurikuler,
          builder: (_, _) => const EkstrakurikulerPage(),
        ),
        GoRoute(
          path: AppRoutes.kalender,
          builder: (_, _) => const KalenderPage(),
        ),
        GoRoute(path: AppRoutes.bk, builder: (_, _) => const BkPage()),
        GoRoute(path: AppRoutes.ujian, builder: (_, _) => const UjianPage()),
        GoRoute(path: AppRoutes.tmb, builder: (_, _) => const TmbPage()),
        GoRoute(path: AppRoutes.ppdb, builder: (_, _) => const PpdbPage()),
        GoRoute(path: AppRoutes.ews, builder: (_, _) => const EwsPage()),
      ],
    ),
    GoRoute(
      path: AppRoutes.siswaInsight,
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '');
        if (id == null) {
          return const _SiswaInsightMissingId();
        }
        return SiswaInsightPage(siswaId: id);
      },
    ),
  ],
);

class _SiswaInsightMissingId extends StatelessWidget {
  const _SiswaInsightMissingId();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Insight 360°'), centerTitle: true),
      body: const Center(child: Text('ID siswa tidak valid')),
    );
  }
}

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
