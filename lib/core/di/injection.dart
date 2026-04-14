import 'package:get_it/get_it.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../api/api_client.dart';
import '../storage/token_storage.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/domain/usecases/get_current_user_usecase.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/absensi/data/datasources/absensi_remote_datasource.dart';
import '../../features/absensi/data/repositories/absensi_repository_impl.dart';
import '../../features/absensi/domain/repositories/absensi_repository.dart';
import '../../features/absensi/domain/usecases/get_absensi_siswa_usecase.dart';
import '../../features/absensi/domain/usecases/get_absensi_guru_usecase.dart';
import '../../features/absensi/presentation/bloc/absensi_bloc.dart';

final sl = GetIt.instance;

Future<void> configureDependencies() async {
  // ── External ─────────────────────────────────────────────────────────────
  const secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  sl.registerLazySingleton(() => secureStorage);

  // ── Core ──────────────────────────────────────────────────────────────────
  sl.registerLazySingleton(() => ApiClient(sl()));
  sl.registerLazySingleton(() => TokenStorage(sl()));

  // ── Auth feature ──────────────────────────────────────────────────────────
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(sl<ApiClient>().dio),
  );
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl(), sl()),
  );
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));
  sl.registerLazySingleton(() => GetCurrentUserUseCase(sl()));
  sl.registerLazySingleton(
    () => AuthBloc(
      loginUseCase: sl(),
      logoutUseCase: sl(),
      getCurrentUserUseCase: sl(),
      tokenStorage: sl(),
    ),
  );

  // ── Absensi feature ───────────────────────────────────────────────────────
  sl.registerLazySingleton<AbsensiRemoteDataSource>(
    () => AbsensiRemoteDataSourceImpl(sl<ApiClient>().dio),
  );
  sl.registerLazySingleton<AbsensiRepository>(
    () => AbsensiRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => GetAbsensiSiswaListUseCase(sl()));
  sl.registerLazySingleton(() => GetAbsensiSiswaGeneralUseCase(sl()));
  sl.registerLazySingleton(() => GetAbsensiGuruListUseCase(sl()));
  sl.registerFactory(
    () => AbsensiBloc(
      getSiswaList: sl(),
      getSiswaGeneral: sl(),
      getGuruList: sl(),
    ),
  );
}
