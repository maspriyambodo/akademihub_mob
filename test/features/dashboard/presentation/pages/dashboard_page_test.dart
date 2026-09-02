import 'package:akademihub_mob/core/error/result.dart' as app_result;
import 'package:akademihub_mob/core/notifications/push_notification_service.dart';
import 'package:akademihub_mob/core/storage/token_storage.dart';
import 'package:akademihub_mob/core/theme/app_theme.dart';
import 'package:akademihub_mob/features/auth/domain/entities/user_entity.dart';
import 'package:akademihub_mob/features/auth/domain/repositories/auth_repository.dart';
import 'package:akademihub_mob/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:akademihub_mob/features/auth/domain/usecases/login_usecase.dart';
import 'package:akademihub_mob/features/auth/domain/usecases/logout_usecase.dart';
import 'package:akademihub_mob/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:akademihub_mob/features/dashboard/domain/entities/dashboard_entity.dart';
import 'package:akademihub_mob/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:akademihub_mob/features/dashboard/domain/usecases/get_dashboard_usecase.dart';
import 'package:akademihub_mob/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:akademihub_mob/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuthRepository implements AuthRepository {
  final UserEntity user;
  _FakeAuthRepository(this.user);

  @override
  Future<app_result.Result<UserEntity>> login(
    String username,
    String password,
  ) async => app_result.success(user);

  @override
  Future<app_result.Result<void>> logout() async => app_result.success(null);

  @override
  Future<app_result.Result<UserEntity>> getCurrentUser() async =>
      app_result.success(user);
}

class _FakeDashboardRepository implements DashboardRepository {
  final DashboardEntity data;
  _FakeDashboardRepository(this.data);

  @override
  Future<DashboardEntity> getDashboardData() async => data;
}

void main() {
  testWidgets('renders Siswa dashboard with hero header and role label', (
    tester,
  ) async {
    const user = UserEntity(
      id: 1,
      name: 'Budi Siswa',
      email: 'budi@test.com',
      role: 'siswa',
      permissions: ['materi.view', 'tugas.view'],
    );
    const data = DashboardEntity(
      role: 'siswa',
      attendanceSummary: [
        {'status': 'hadir', 'total': 20},
        {'status': 'sakit', 'total': 1},
      ],
      upcomingTasks: [
        {'judul': 'Tugas Matematika', 'deadline': 'Besok'},
      ],
    );

    final authBloc = AuthBloc(
      loginUseCase: LoginUseCase(_FakeAuthRepository(user)),
      logoutUseCase: LogoutUseCase(_FakeAuthRepository(user)),
      getCurrentUserUseCase: GetCurrentUserUseCase(_FakeAuthRepository(user)),
      tokenStorage: TokenStorage(const FlutterSecureStorage()),
      pushNotifications: PushNotificationService(Dio()),
    );
    authBloc.emit(AuthAuthenticated(user));
    addTearDown(authBloc.close);

    final dashboardBloc = DashboardBloc(
      GetDashboardDataUseCase(_FakeDashboardRepository(data)),
    );
    dashboardBloc.emit(DashboardLoaded(data));
    addTearDown(dashboardBloc.close);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: authBloc),
            BlocProvider<DashboardBloc>.value(value: dashboardBloc),
          ],
          child: const DashboardPage(),
        ),
      ),
    );

    expect(find.text('RUANG SISWA'), findsOneWidget);
    expect(find.text('Halo, Budi Siswa'), findsOneWidget);
    expect(find.text('Ringkasan Kehadiran'), findsOneWidget);
    expect(find.text('Hadir'), findsOneWidget);
    expect(find.text('20'), findsOneWidget);
    expect(find.text('Tugas Mendatang'), findsOneWidget);
    expect(find.text('Tugas Matematika'), findsOneWidget);
  });

  testWidgets('renders error view with retry button on DashboardError state', (
    tester,
  ) async {
    const user = UserEntity(
      id: 2,
      name: 'Guru Siti',
      email: 'siti@test.com',
      role: 'guru',
      permissions: [],
    );
    const data = DashboardEntity(role: 'guru');

    final authBloc = AuthBloc(
      loginUseCase: LoginUseCase(_FakeAuthRepository(user)),
      logoutUseCase: LogoutUseCase(_FakeAuthRepository(user)),
      getCurrentUserUseCase: GetCurrentUserUseCase(_FakeAuthRepository(user)),
      tokenStorage: TokenStorage(const FlutterSecureStorage()),
      pushNotifications: PushNotificationService(Dio()),
    );
    authBloc.emit(AuthAuthenticated(user));
    addTearDown(authBloc.close);

    final dashboardBloc = DashboardBloc(
      GetDashboardDataUseCase(_FakeDashboardRepository(data)),
    );
    dashboardBloc.emit(DashboardError('Koneksi internet terputus'));
    addTearDown(dashboardBloc.close);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: authBloc),
            BlocProvider<DashboardBloc>.value(value: dashboardBloc),
          ],
          child: const DashboardPage(),
        ),
      ),
    );

    expect(find.text('Dashboard Belum Dapat Dimuat'), findsOneWidget);
    expect(find.text('Koneksi internet terputus'), findsOneWidget);
    expect(find.text('Coba Lagi'), findsOneWidget);
  });
}
