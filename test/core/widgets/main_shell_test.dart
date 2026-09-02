import 'package:akademihub_mob/core/error/result.dart';
import 'package:akademihub_mob/core/notifications/push_notification_service.dart';
import 'package:akademihub_mob/core/router/app_router.dart';
import 'package:akademihub_mob/core/storage/token_storage.dart';
import 'package:akademihub_mob/core/theme/app_theme.dart';
import 'package:akademihub_mob/core/widgets/main_shell.dart';
import 'package:akademihub_mob/features/auth/domain/entities/user_entity.dart';
import 'package:akademihub_mob/features/auth/domain/repositories/auth_repository.dart';
import 'package:akademihub_mob/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:akademihub_mob/features/auth/domain/usecases/login_usecase.dart';
import 'package:akademihub_mob/features/auth/domain/usecases/logout_usecase.dart';
import 'package:akademihub_mob/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _FakeAuthRepository implements AuthRepository {
  final UserEntity user;
  _FakeAuthRepository(this.user);

  @override
  Future<Result<UserEntity>> login(String username, String password) async =>
      success(user);

  @override
  Future<Result<void>> logout() async => success(null);

  @override
  Future<Result<UserEntity>> getCurrentUser() async => success(user);
}

AuthBloc _createAuthBloc(UserEntity user) {
  final repo = _FakeAuthRepository(user);
  return AuthBloc(
    loginUseCase: LoginUseCase(repo),
    logoutUseCase: LogoutUseCase(repo),
    getCurrentUserUseCase: GetCurrentUserUseCase(repo),
    tokenStorage: TokenStorage(const FlutterSecureStorage()),
    pushNotifications: PushNotificationService(Dio()),
  );
}

Widget _buildTestApp({
  required AuthBloc authBloc,
  required String initialLocation,
}) {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            builder: (context, state) => const Text('Dashboard Content'),
          ),
          GoRoute(
            path: AppRoutes.absensi,
            builder: (context, state) => const Text('Absensi Content'),
          ),
          GoRoute(
            path: AppRoutes.jadwal,
            builder: (context, state) => const Text('Jadwal Content'),
          ),
          GoRoute(
            path: AppRoutes.tugas,
            builder: (context, state) => const Text('Tugas Content'),
          ),
          GoRoute(
            path: AppRoutes.profil,
            builder: (context, state) => const Text('Profil Content'),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const Text('Login Screen'),
      ),
    ],
  );

  return BlocProvider<AuthBloc>.value(
    value: authBloc,
    child: MaterialApp.router(theme: AppTheme.lightTheme, routerConfig: router),
  );
}

void main() {
  const adminUser = UserEntity(
    id: 1,
    name: 'Admin Test',
    email: 'admin@school.id',
    role: 'admin',
    permissions: ['absensi-siswa.view', 'jadwal-pelajaran.view', 'tugas.view'],
  );

  const restrictedUser = UserEntity(
    id: 2,
    name: 'User No Permissions',
    email: 'user@school.id',
    role: 'siswa',
    permissions: [],
  );

  testWidgets('renders tabs based on permissions', (tester) async {
    final bloc = _createAuthBloc(adminUser);
    addTearDown(bloc.close);
    bloc.emit(AuthAuthenticated(adminUser));

    await tester.pumpWidget(
      _buildTestApp(authBloc: bloc, initialLocation: AppRoutes.dashboard),
    );
    await tester.pumpAndSettle();

    expect(find.text('Beranda'), findsOneWidget);
    expect(find.text('Absensi'), findsOneWidget);
    expect(find.text('Jadwal'), findsOneWidget);
    expect(find.text('Tugas'), findsOneWidget);
    expect(find.text('Profil'), findsOneWidget);
  });

  testWidgets('hides tabs that do not have permissions', (tester) async {
    final bloc = _createAuthBloc(restrictedUser);
    addTearDown(bloc.close);
    bloc.emit(AuthAuthenticated(restrictedUser));

    await tester.pumpWidget(
      _buildTestApp(authBloc: bloc, initialLocation: AppRoutes.dashboard),
    );
    await tester.pumpAndSettle();

    expect(find.text('Beranda'), findsOneWidget);
    expect(find.text('Profil'), findsOneWidget);
    expect(find.text('Absensi'), findsNothing);
    expect(find.text('Jadwal'), findsNothing);
    expect(find.text('Tugas'), findsNothing);
  });

  testWidgets('renders navigation rail on expanded width (>=840dp)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final bloc = _createAuthBloc(adminUser);
    addTearDown(bloc.close);
    bloc.emit(AuthAuthenticated(adminUser));

    await tester.pumpWidget(
      _buildTestApp(authBloc: bloc, initialLocation: AppRoutes.dashboard),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('renders safely on compact 320dp width and textScale 2.0', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final bloc = _createAuthBloc(adminUser);
    addTearDown(bloc.close);
    bloc.emit(AuthAuthenticated(adminUser));

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(320, 568),
          textScaler: TextScaler.linear(2.0),
        ),
        child: _buildTestApp(
          authBloc: bloc,
          initialLocation: AppRoutes.dashboard,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
