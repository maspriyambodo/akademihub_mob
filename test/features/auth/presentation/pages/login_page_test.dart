import 'package:akademihub_mob/core/error/failures.dart';
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
import 'package:akademihub_mob/features/auth/presentation/pages/login_page.dart';
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
  ) async {
    if (username == 'error_user') {
      return app_result.fail(const AuthFailure('Kredensial tidak valid'));
    }
    return app_result.success(user);
  }

  @override
  Future<app_result.Result<void>> logout() async => app_result.success(null);

  @override
  Future<app_result.Result<UserEntity>> getCurrentUser() async =>
      app_result.success(user);
}

AuthBloc _createAuthBloc([UserEntity? user]) {
  final testUser =
      user ??
      const UserEntity(
        id: 1,
        name: 'Siswa Test',
        email: 'siswa@school.id',
        role: 'siswa',
      );
  final repo = _FakeAuthRepository(testUser);
  return AuthBloc(
    loginUseCase: LoginUseCase(repo),
    logoutUseCase: LogoutUseCase(repo),
    getCurrentUserUseCase: GetCurrentUserUseCase(repo),
    tokenStorage: TokenStorage(const FlutterSecureStorage()),
    pushNotifications: PushNotificationService(Dio()),
  );
}

Widget _wrap(AuthBloc bloc) {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    home: BlocProvider<AuthBloc>.value(value: bloc, child: const LoginPage()),
  );
}

void main() {
  testWidgets('renders login page brand elements, form fields, and CTA', (
    tester,
  ) async {
    final bloc = _createAuthBloc();
    addTearDown(bloc.close);

    await tester.pumpWidget(_wrap(bloc));
    await tester.pumpAndSettle();

    expect(find.text('RUANG BELAJAR DIGITAL'), findsOneWidget);
    expect(find.text('AkademiHub'), findsOneWidget);
    expect(find.text('Selamat datang kembali'), findsOneWidget);
    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Masuk'), findsOneWidget);
  });

  testWidgets('validates empty inputs on submit', (tester) async {
    final bloc = _createAuthBloc();
    addTearDown(bloc.close);

    await tester.pumpWidget(_wrap(bloc));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Masuk'));
    await tester.pumpAndSettle();

    expect(find.text('Username wajib diisi'), findsOneWidget);
    expect(find.text('Password wajib diisi'), findsOneWidget);
  });

  testWidgets('toggles password visibility', (tester) async {
    final bloc = _createAuthBloc();
    addTearDown(bloc.close);

    await tester.pumpWidget(_wrap(bloc));
    await tester.pumpAndSettle();

    final toggleFinder = find.byTooltip('Tampilkan password');
    expect(toggleFinder, findsOneWidget);

    await tester.tap(toggleFinder);
    await tester.pumpAndSettle();

    expect(find.byTooltip('Sembunyikan password'), findsOneWidget);
  });

  testWidgets('submits login credentials and displays loading state', (
    tester,
  ) async {
    final bloc = _createAuthBloc();
    addTearDown(bloc.close);

    await tester.pumpWidget(_wrap(bloc));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == 'Username',
      ),
      'siswa123',
    );
    await tester.enterText(
      find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == 'Password',
      ),
      'password123',
    );

    bloc.emit(AuthLoading());
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('displays error snackbar on AuthError state', (tester) async {
    final bloc = _createAuthBloc();
    addTearDown(bloc.close);

    await tester.pumpWidget(_wrap(bloc));
    await tester.pumpAndSettle();

    bloc.emit(AuthError('Kredensial tidak valid'));
    await tester.pumpAndSettle();

    expect(find.text('Kredensial tidak valid'), findsOneWidget);
  });

  testWidgets('renders split brand panel on expanded layout (>=840dp)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final bloc = _createAuthBloc();
    addTearDown(bloc.close);

    await tester.pumpWidget(_wrap(bloc));
    await tester.pumpAndSettle();

    expect(
      find.text('Ruang Belajar Digital\nTerpadu & Modern'),
      findsOneWidget,
    );
    expect(find.text('Akademik'), findsOneWidget);
    expect(find.text('Kehadiran & Presensi'), findsOneWidget);
    expect(find.text('Administrasi & Keuangan'), findsOneWidget);
  });

  testWidgets('renders safely on 320dp width and textScale 2.0', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final bloc = _createAuthBloc();
    addTearDown(bloc.close);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(320, 568),
          textScaler: TextScaler.linear(2.0),
        ),
        child: _wrap(bloc),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Selamat datang kembali'), findsOneWidget);
  });
}
