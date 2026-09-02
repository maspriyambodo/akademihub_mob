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
import 'package:akademihub_mob/features/jadwal/domain/entities/jadwal_pelajaran_entity.dart';
import 'package:akademihub_mob/features/jadwal/domain/repositories/jadwal_repository.dart';
import 'package:akademihub_mob/features/jadwal/domain/usecases/get_jadwal_kelas_usecase.dart';
import 'package:akademihub_mob/features/jadwal/domain/usecases/get_jadwal_list_usecase.dart';
import 'package:akademihub_mob/features/jadwal/presentation/bloc/jadwal_bloc.dart';
import 'package:akademihub_mob/features/jadwal/presentation/pages/jadwal_page.dart';
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

class _FakeJadwalRepository implements JadwalRepository {
  final List<JadwalPelajaranEntity> items;
  _FakeJadwalRepository(this.items);

  @override
  Future<app_result.Result<List<JadwalPelajaranEntity>>> getJadwalByKelas(
    int kelasId,
  ) async => app_result.success(items);

  @override
  Future<app_result.Result<List<JadwalPelajaranEntity>>> getJadwalByKelasHari(
    int kelasId,
    String hari,
  ) async => app_result.success(items);

  @override
  Future<app_result.Result<List<JadwalPelajaranEntity>>> getJadwalList({
    int? kelasId,
    int? guruId,
    String? hari,
    int page = 1,
    int perPage = 20,
  }) async => app_result.success(items);
}

void main() {
  testWidgets('renders jadwal page with day selector and list cards', (
    tester,
  ) async {
    const user = UserEntity(
      id: 1,
      name: 'Siswa Test',
      email: 'siswa@test.com',
      role: 'siswa',
      profile: {
        'id': 10,
        'kelas': {'id': 1, 'nama': 'X RPL 1'},
      },
    );

    final todayCode = hariCodeFromWeekday(DateTime.now().weekday);
    final items = [
      JadwalPelajaranEntity(
        id: 1,
        mapelNama: 'Matematika',
        guruNama: 'Pak Budi',
        hari: todayCode,
        jamMulai: '07:00',
        jamSelesai: '08:30',
        ruangan: 'Lab 1',
      ),
    ];

    final authBloc = AuthBloc(
      loginUseCase: LoginUseCase(_FakeAuthRepository(user)),
      logoutUseCase: LogoutUseCase(_FakeAuthRepository(user)),
      getCurrentUserUseCase: GetCurrentUserUseCase(_FakeAuthRepository(user)),
      tokenStorage: TokenStorage(const FlutterSecureStorage()),
      pushNotifications: PushNotificationService(Dio()),
    );
    authBloc.emit(AuthAuthenticated(user));
    addTearDown(authBloc.close);

    final repo = _FakeJadwalRepository(items);
    final jadwalBloc = JadwalBloc(
      getJadwalKelas: GetJadwalKelasUseCase(repo),
      getJadwalKelasHari: GetJadwalKelasHariUseCase(repo),
      getJadwalList: GetJadwalListUseCase(repo),
    );
    addTearDown(jadwalBloc.close);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: authBloc),
            BlocProvider<JadwalBloc>.value(value: jadwalBloc),
          ],
          child: const JadwalView(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Jadwal Pelajaran'), findsOneWidget);
    expect(find.text('Matematika'), findsOneWidget);
    expect(find.text('Pak Budi'), findsOneWidget);
  });
}
