import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/di/injection.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'core/notifications/push_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  await sl<PushNotificationService>().initialize();
  runApp(const AkademiHubApp());
}

class AkademiHubApp extends StatelessWidget {
  const AkademiHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: sl<AuthBloc>()),
        BlocProvider(create: (_) => sl<DashboardBloc>()),
      ],
      child: MaterialApp.router(
        title: 'AkademiHub',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        routerConfig: router,
        builder: (context, child) {
          // Batasi skala font sistem. Pengaturan aksesibilitas Android bisa
          // mencapai 2.0x dan itu merusak layout bertinggi tetap. Rentang
          // 0.85–1.3 tetap menghormati preferensi pengguna tanpa membuat
          // teks meluber dari kartu/baris.
          final mq = MediaQuery.of(context);
          final skala = mq.textScaler.scale(1).clamp(0.85, 1.3);
          return MediaQuery(
            data: mq.copyWith(textScaler: TextScaler.linear(skala)),
            child: child ?? const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}
