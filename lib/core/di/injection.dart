import 'package:get_it/get_it.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_client.dart';
import '../notifications/push_notification_service.dart';
import '../storage/token_storage.dart';
import '../storage/answer_outbox.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/domain/usecases/get_current_user_usecase.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/wali/guardian_child_selector.dart';
import '../../features/organisasi/data/organisasi_remote_datasource.dart';
import '../../features/absensi/data/datasources/absensi_remote_datasource.dart';
import '../../features/absensi/data/repositories/absensi_repository_impl.dart';
import '../../features/absensi/domain/repositories/absensi_repository.dart';
import '../../features/absensi/domain/usecases/get_absensi_siswa_usecase.dart';
import '../../features/absensi/domain/usecases/get_absensi_guru_usecase.dart';
import '../../features/absensi/presentation/bloc/absensi_bloc.dart';
import '../../features/absensi/data/services/attendance_location_service.dart';
import '../../features/dashboard/data/datasources/dashboard_remote_datasource.dart';
import '../../features/dashboard/data/repositories/dashboard_repository_impl.dart';
import '../../features/dashboard/domain/repositories/dashboard_repository.dart';
import '../../features/dashboard/domain/usecases/get_dashboard_usecase.dart';
import '../../features/dashboard/presentation/bloc/dashboard_bloc.dart';
import '../../features/jadwal/data/datasources/jadwal_remote_datasource.dart';
import '../../features/jadwal/data/repositories/jadwal_repository_impl.dart';
import '../../features/jadwal/domain/repositories/jadwal_repository.dart';
import '../../features/jadwal/domain/usecases/get_jadwal_kelas_usecase.dart';
import '../../features/jadwal/domain/usecases/get_jadwal_list_usecase.dart';
import '../../features/jadwal/presentation/bloc/jadwal_bloc.dart';
import '../../features/nilai/data/datasources/nilai_remote_datasource.dart';
import '../../features/nilai/data/repositories/nilai_repository_impl.dart';
import '../../features/nilai/domain/repositories/nilai_repository.dart';
import '../../features/nilai/domain/usecases/get_nilai_siswa_usecase.dart';
import '../../features/nilai/domain/usecases/get_nilai_general_usecase.dart';
import '../../features/nilai/domain/usecases/create_nilai_usecase.dart';
import '../../features/nilai/domain/usecases/update_nilai_usecase.dart';
import '../../features/nilai/domain/usecases/delete_nilai_usecase.dart';
import '../../features/nilai/presentation/bloc/nilai_bloc.dart';
import '../../features/rapor/data/datasources/rapor_remote_datasource.dart';
import '../../features/rapor/data/repositories/rapor_repository_impl.dart';
import '../../features/rapor/domain/repositories/rapor_repository.dart';
import '../../features/rapor/domain/usecases/get_rapor_list_usecase.dart';
import '../../features/rapor/domain/usecases/get_rapor_detail_usecase.dart';
import '../../features/rapor/domain/usecases/export_rapor_usecase.dart';
import '../../features/rapor/domain/usecases/manage_rapor_usecases.dart';
import '../../features/rapor/presentation/bloc/rapor_bloc.dart';
import '../../features/rapor/presentation/bloc/rapor_detail_bloc.dart';
import '../../features/notifications/data/datasources/notifications_remote_datasource.dart';
import '../../features/notifications/data/repositories/notifications_repository_impl.dart';
import '../../features/notifications/domain/repositories/notifications_repository.dart';
import '../../features/notifications/domain/usecases/get_notifications_usecase.dart';
import '../../features/notifications/domain/usecases/get_unread_count_usecase.dart';
import '../../features/notifications/domain/usecases/mark_notification_read_usecase.dart';
import '../../features/notifications/domain/usecases/mark_all_notifications_read_usecase.dart';
import '../../features/notifications/presentation/bloc/notifications_bloc.dart';
import '../../features/tugas/data/datasources/tugas_remote_datasource.dart';
import '../../features/tugas/data/repositories/tugas_repository_impl.dart';
import '../../features/tugas/domain/repositories/tugas_repository.dart';
import '../../features/tugas/domain/usecases/get_tugas_usecase.dart';
import '../../features/tugas/domain/usecases/get_pengumpulan_usecase.dart';
import '../../features/tugas/domain/usecases/kumpulkan_tugas_usecase.dart';
import '../../features/tugas/domain/usecases/nilai_tugas_usecase.dart';
import '../../features/tugas/domain/usecases/manage_tugas_usecases.dart';
import '../../features/tugas/presentation/bloc/tugas_bloc.dart';
import '../../features/tugas/presentation/bloc/pengumpulan_bloc.dart';
import '../../features/keuangan/data/datasources/keuangan_remote_datasource.dart';
import '../../features/keuangan/data/repositories/keuangan_repository_impl.dart';
import '../../features/keuangan/domain/repositories/keuangan_repository.dart';
import '../../features/keuangan/domain/usecases/get_pembayaran_spp_usecase.dart';
import '../../features/keuangan/domain/usecases/get_status_pembayaran_usecase.dart';
import '../../features/keuangan/domain/usecases/get_tarif_spp_usecase.dart';
import '../../features/keuangan/domain/usecases/get_laporan_periode_usecase.dart';
import '../../features/keuangan/domain/usecases/bayar_spp_usecase.dart';
import '../../features/keuangan/presentation/bloc/keuangan_bloc.dart';
import '../../features/keuangan/presentation/bloc/keuangan_detail_bloc.dart';
import '../../features/profil/data/datasources/profil_local_datasource.dart';
import '../../features/profil/data/datasources/profil_remote_datasource.dart';
import '../../features/profil/data/repositories/profil_repository_impl.dart';
import '../../features/profil/domain/repositories/profil_repository.dart';
import '../../features/profil/domain/usecases/get_app_info_usecase.dart';
import '../../features/profil/domain/usecases/get_perangkat_usecase.dart';
import '../../features/profil/domain/usecases/get_sekolah_usecase.dart';
import '../../features/profil/presentation/bloc/profil_bloc.dart';
import '../../features/materi/data/datasources/materi_remote_datasource.dart';
import '../../features/materi/data/repositories/materi_repository_impl.dart';
import '../../features/materi/domain/repositories/materi_repository.dart';
import '../../features/materi/domain/usecases/get_materi_usecase.dart';
import '../../features/materi/domain/usecases/log_akses_materi_usecase.dart';
import '../../features/materi/domain/usecases/create_materi_usecase.dart';
import '../../features/materi/domain/usecases/update_materi_usecase.dart';
import '../../features/materi/domain/usecases/delete_materi_usecase.dart';
import '../../features/materi/presentation/bloc/materi_bloc.dart';
import '../../features/materi/presentation/bloc/materi_detail_bloc.dart';
import '../../features/forum/data/datasources/forum_remote_datasource.dart';
import '../../features/forum/data/repositories/forum_repository_impl.dart';
import '../../features/forum/domain/repositories/forum_repository.dart';
import '../../features/forum/domain/usecases/get_forum_usecase.dart';
import '../../features/forum/domain/usecases/create_forum_usecase.dart';
import '../../features/forum/domain/usecases/update_forum_usecase.dart';
import '../../features/forum/domain/usecases/delete_forum_usecase.dart';
import '../../features/forum/presentation/bloc/forum_bloc.dart';
import '../../features/forum/presentation/bloc/forum_detail_bloc.dart';
import '../../features/ekstrakurikuler/data/datasources/ekstrakurikuler_remote_datasource.dart';
import '../../features/ekstrakurikuler/data/repositories/ekstrakurikuler_repository_impl.dart';
import '../../features/ekstrakurikuler/domain/repositories/ekstrakurikuler_repository.dart';
import '../../features/ekstrakurikuler/domain/usecases/get_ekstrakurikuler_usecase.dart';
import '../../features/ekstrakurikuler/domain/usecases/get_pendaftaran_usecase.dart';
import '../../features/ekstrakurikuler/domain/usecases/daftar_ekstrakurikuler_usecase.dart';
import '../../features/ekstrakurikuler/domain/usecases/keluar_ekstrakurikuler_usecase.dart';
import '../../features/ekstrakurikuler/presentation/bloc/ekstrakurikuler_bloc.dart';
import '../../features/ekstrakurikuler/presentation/bloc/ekstrakurikuler_detail_bloc.dart';
import '../../features/kalender/data/datasources/kalender_remote_datasource.dart';
import '../../features/kalender/data/repositories/kalender_repository_impl.dart';
import '../../features/kalender/domain/repositories/kalender_repository.dart';
import '../../features/kalender/domain/usecases/get_kalender_events_usecase.dart';
import '../../features/kalender/domain/usecases/get_kalender_harian_usecase.dart';
import '../../features/kalender/domain/usecases/get_kalender_tipe_usecase.dart';
import '../../features/kalender/domain/usecases/get_kalender_konteks_usecase.dart';
import '../../features/kalender/presentation/bloc/kalender_bloc.dart';
import '../../features/bk/data/datasources/bk_remote_datasource.dart';
import '../../features/bk/data/repositories/bk_repository_impl.dart';
import '../../features/bk/domain/repositories/bk_repository.dart';
import '../../features/bk/domain/usecases/create_bk_hasil_usecase.dart';
import '../../features/bk/domain/usecases/create_bk_kasus_usecase.dart';
import '../../features/bk/domain/usecases/create_bk_sesi_usecase.dart';
import '../../features/bk/domain/usecases/create_bk_tindakan_usecase.dart';
import '../../features/bk/domain/usecases/get_bk_jenis_usecase.dart';
import '../../features/bk/domain/usecases/get_bk_kasus_relasi_usecase.dart';
import '../../features/bk/domain/usecases/get_bk_kasus_usecase.dart';
import '../../features/bk/domain/usecases/search_bk_siswa_usecase.dart';
import '../../features/bk/presentation/bloc/bk_bloc.dart';
import '../../features/bk/presentation/bloc/bk_detail_bloc.dart';
import '../../features/bk/presentation/bloc/bk_form_bloc.dart';
import '../../features/ujian/data/datasources/ujian_remote_datasource.dart';
import '../../features/ujian/data/repositories/ujian_repository_impl.dart';
import '../../features/ujian/domain/repositories/ujian_repository.dart';
import '../../features/ujian/domain/usecases/export_ranking_usecase.dart';
import '../../features/ujian/domain/usecases/generate_ranking_usecase.dart';
import '../../features/ujian/domain/usecases/get_kelas_options_usecase.dart';
// Alias: fitur `nilai` juga punya kelas bernama GetNilaiUjianUseCase.
import '../../features/ujian/domain/usecases/get_nilai_ujian_usecase.dart'
    as ujian_uc;
import '../../features/ujian/domain/usecases/get_ranking_kelas_usecase.dart';
import '../../features/ujian/domain/usecases/get_ujian_by_kelas_usecase.dart';
import '../../features/ujian/presentation/bloc/ujian_bloc.dart';
import '../../features/ujian/presentation/bloc/ujian_nilai_bloc.dart';
import '../../features/tmb/data/datasources/tmb_remote_datasource.dart';
import '../../features/tmb/data/repositories/tmb_repository_impl.dart';
import '../../features/tmb/domain/repositories/tmb_repository.dart';
import '../../features/tmb/domain/usecases/daftar_tmb_peserta_usecase.dart';
import '../../features/tmb/domain/usecases/get_tmb_hasil_by_peserta_usecase.dart';
import '../../features/tmb/domain/usecases/get_tmb_jawaban_by_peserta_usecase.dart';
import '../../features/tmb/domain/usecases/get_tmb_pertanyaan_usecase.dart';
import '../../features/tmb/domain/usecases/get_tmb_peserta_by_siswa_usecase.dart';
import '../../features/tmb/domain/usecases/get_tmb_peserta_by_tes_usecase.dart';
import '../../features/tmb/domain/usecases/get_tmb_tes_by_kelas_usecase.dart';
import '../../features/tmb/domain/usecases/get_tmb_tes_list_usecase.dart';
import '../../features/tmb/domain/usecases/kirim_tmb_jawaban_usecase.dart';
import '../../features/tmb/domain/usecases/mulai_tmb_usecase.dart';
import '../../features/tmb/domain/usecases/selesaikan_tmb_usecase.dart';
import '../../features/tmb/presentation/bloc/tmb_bloc.dart';
import '../../features/tmb/presentation/bloc/tmb_hasil_bloc.dart';
import '../../features/tmb/presentation/bloc/tmb_pengerjaan_bloc.dart';
import '../../features/tmb/presentation/bloc/tmb_peserta_bloc.dart';
import '../../features/ews/data/datasources/ews_remote_datasource.dart';
import '../../features/ews/data/repositories/ews_repository_impl.dart';
import '../../features/ews/domain/repositories/ews_repository.dart';
import '../../features/ews/domain/usecases/get_ews_alerts_usecase.dart';
import '../../features/ews/domain/usecases/get_ews_alert_detail_usecase.dart';
import '../../features/ews/domain/usecases/resolve_ews_alert_usecase.dart';
import '../../features/ews/domain/usecases/trigger_ews_check_usecase.dart';
import '../../features/ews/presentation/bloc/ews_bloc.dart';
import '../../features/siswa_insight/data/datasources/siswa_insight_remote_datasource.dart';
import '../../features/siswa_insight/data/repositories/siswa_insight_repository_impl.dart';
import '../../features/siswa_insight/domain/repositories/siswa_insight_repository.dart';
import '../../features/siswa_insight/domain/usecases/get_siswa_insight_usecase.dart';
import '../../features/siswa_insight/domain/usecases/get_siswa_risk_profile_usecase.dart';
import '../../features/siswa_insight/domain/usecases/invalidate_siswa_insight_cache_usecase.dart';
import '../../features/siswa_insight/presentation/bloc/siswa_insight_bloc.dart';

final sl = GetIt.instance;

Future<void> configureDependencies() async {
  // ── External ─────────────────────────────────────────────────────────────
  const secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  sl.registerLazySingleton(() => secureStorage);
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('active_tenant');

  // ── Core ──────────────────────────────────────────────────────────────────
  final apiClient = ApiClient(secureStorage);
  sl.registerSingleton(apiClient);
  sl.registerSingleton(await AnswerOutbox.open(secureStorage));
  sl.registerLazySingleton(() => GuardianChildService(sl<ApiClient>().dio));
  sl.registerLazySingleton(
    () => OrganisasiRemoteDataSource(sl<ApiClient>().dio),
  );
  sl.registerLazySingleton(() => TokenStorage(sl()));
  sl.registerLazySingleton(() => PushNotificationService(sl<ApiClient>().dio));

  // ── Auth feature ──────────────────────────────────────────────────────────
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(sl<ApiClient>().dio),
  );
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl(), sl(), sl(), sl()),
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
      pushNotifications: sl(),
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
  sl.registerLazySingleton(() => CheckInAbsensiUseCase(sl()));
  sl.registerLazySingleton(() => CheckOutAbsensiUseCase(sl()));
  sl.registerLazySingleton(() => GetCurrentAbsensiUseCase(sl()));
  sl.registerLazySingleton(() => AttendanceLocationService());
  sl.registerLazySingleton(() => GetAbsensiSiswaGeneralUseCase(sl()));
  sl.registerLazySingleton(() => GetAbsensiGuruListUseCase(sl()));
  sl.registerFactory(
    () => AbsensiBloc(
      getSiswaList: sl(),
      getSiswaGeneral: sl(),
      getGuruList: sl(),
      checkIn: sl(),
      checkOut: sl(),
      getCurrent: sl(),
      locationService: sl(),
    ),
  );

  // ── Dashboard feature ─────────────────────────────────────────────────────
  sl.registerLazySingleton<DashboardRemoteDataSource>(
    () => DashboardRemoteDataSourceImpl(sl<ApiClient>().dio),
  );
  sl.registerLazySingleton<DashboardRepository>(
    () => DashboardRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => GetDashboardDataUseCase(sl()));
  sl.registerFactory(() => DashboardBloc(sl()));

  // ── Jadwal feature ────────────────────────────────────────────────────────
  sl.registerLazySingleton<JadwalRemoteDataSource>(
    () => JadwalRemoteDataSourceImpl(sl<ApiClient>().dio),
  );
  sl.registerLazySingleton<JadwalRepository>(() => JadwalRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetJadwalKelasUseCase(sl()));
  sl.registerLazySingleton(() => GetJadwalKelasHariUseCase(sl()));
  sl.registerLazySingleton(() => GetJadwalListUseCase(sl()));
  sl.registerFactory(
    () => JadwalBloc(
      getJadwalKelas: sl(),
      getJadwalKelasHari: sl(),
      getJadwalList: sl(),
    ),
  );

  // ── Nilai feature ─────────────────────────────────────────────────────────
  sl.registerLazySingleton<NilaiRemoteDataSource>(
    () => NilaiRemoteDataSourceImpl(sl<ApiClient>().dio),
  );
  sl.registerLazySingleton<NilaiRepository>(() => NilaiRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetNilaiSiswaUseCase(sl()));
  sl.registerLazySingleton(() => GetNilaiGeneralUseCase(sl()));
  sl.registerLazySingleton(() => GetNilaiUjianUseCase(sl()));
  sl.registerLazySingleton(() => GetRataRataNilaiUseCase(sl()));
  sl.registerLazySingleton(() => CreateNilaiUseCase(sl()));
  sl.registerLazySingleton(() => UpdateNilaiUseCase(sl()));
  sl.registerLazySingleton(() => DeleteNilaiUseCase(sl()));
  sl.registerFactory(
    () => NilaiBloc(
      getNilaiSiswa: sl(),
      getNilaiGeneral: sl(),
      getNilaiUjian: sl(),
      getRataRataNilai: sl(),
      createNilai: sl(),
      updateNilai: sl(),
      deleteNilai: sl(),
    ),
  );

  // ── Rapor feature ─────────────────────────────────────────────────────────
  sl.registerLazySingleton<RaporRemoteDataSource>(
    () => RaporRemoteDataSourceImpl(sl<ApiClient>().dio),
  );
  sl.registerLazySingleton<RaporRepository>(() => RaporRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetRaporListUseCase(sl()));
  sl.registerLazySingleton(() => GetRaporBySiswaUseCase(sl()));
  sl.registerLazySingleton(() => GetRaporDetailUseCase(sl()));
  sl.registerLazySingleton(() => ExportRaporUseCase(sl()));
  sl.registerLazySingleton(() => CreateRaporUseCase(sl()));
  sl.registerLazySingleton(() => UpdateRaporUseCase(sl()));
  sl.registerLazySingleton(() => DeleteRaporUseCase(sl()));
  sl.registerFactory(
    () => RaporBloc(
      getRaporList: sl(),
      getRaporBySiswa: sl(),
      createRapor: sl(),
      updateRapor: sl(),
      deleteRapor: sl(),
    ),
  );
  sl.registerFactory(
    () => RaporDetailBloc(getRaporDetail: sl(), exportRapor: sl()),
  );

  // ── Notifications feature ─────────────────────────────────────────────────
  sl.registerLazySingleton<NotificationsRemoteDataSource>(
    () => NotificationsRemoteDataSourceImpl(sl<ApiClient>().dio),
  );
  sl.registerLazySingleton<NotificationsRepository>(
    () => NotificationsRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => GetNotificationsUseCase(sl()));
  sl.registerLazySingleton(() => GetUnreadCountUseCase(sl()));
  sl.registerLazySingleton(() => MarkNotificationReadUseCase(sl()));
  sl.registerLazySingleton(() => MarkAllNotificationsReadUseCase(sl()));
  sl.registerFactory(
    () => NotificationsBloc(
      getNotifications: sl(),
      getUnreadCount: sl(),
      markNotificationRead: sl(),
      markAllNotificationsRead: sl(),
    ),
  );

  // ── Tugas feature ─────────────────────────────────────────────────────────
  sl.registerLazySingleton<TugasRemoteDataSource>(
    () => TugasRemoteDataSourceImpl(sl<ApiClient>().dio),
  );
  sl.registerLazySingleton<TugasRepository>(() => TugasRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetTugasListUseCase(sl()));
  sl.registerLazySingleton(() => GetTugasDetailUseCase(sl()));
  sl.registerLazySingleton(() => GetTugasByKelasUseCase(sl()));
  sl.registerLazySingleton(() => GetTugasByGuruMapelUseCase(sl()));
  sl.registerLazySingleton(() => GetPengumpulanListUseCase(sl()));
  sl.registerLazySingleton(() => GetPengumpulanByTugasUseCase(sl()));
  sl.registerLazySingleton(() => GetPengumpulanBySiswaUseCase(sl()));
  sl.registerLazySingleton(() => KumpulkanTugasUseCase(sl()));
  sl.registerLazySingleton(() => NilaiTugasUseCase(sl()));
  sl.registerLazySingleton(() => CreateTugasUseCase(sl()));
  sl.registerLazySingleton(() => UpdateTugasUseCase(sl()));
  sl.registerLazySingleton(() => DeleteTugasUseCase(sl()));
  sl.registerFactory(
    () => TugasBloc(
      getTugasList: sl(),
      getTugasByKelas: sl(),
      getTugasByGuruMapel: sl(),
      getPengumpulanList: sl(),
      getPengumpulanBySiswa: sl(),
      kumpulkanTugas: sl(),
    ),
  );
  sl.registerFactory(
    () => PengumpulanBloc(getPengumpulanByTugas: sl(), nilaiTugas: sl()),
  );

  // ── Keuangan feature ──────────────────────────────────────────────────────
  sl.registerLazySingleton<KeuanganRemoteDataSource>(
    () => KeuanganRemoteDataSourceImpl(sl<ApiClient>().dio),
  );
  sl.registerLazySingleton<KeuanganRepository>(
    () => KeuanganRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => GetPembayaranListUseCase(sl()));
  sl.registerLazySingleton(() => GetPembayaranBySiswaUseCase(sl()));
  sl.registerLazySingleton(() => GetPembayaranDetailUseCase(sl()));
  sl.registerLazySingleton(() => GetStatusPembayaranUseCase(sl()));
  sl.registerLazySingleton(() => GetTunggakanUseCase(sl()));
  sl.registerLazySingleton(() => HitungDendaUseCase(sl()));
  sl.registerLazySingleton(() => GetTarifSppListUseCase(sl()));
  sl.registerLazySingleton(() => GetTarifSppDetailUseCase(sl()));
  sl.registerLazySingleton(() => GetTarifSppByKelasUseCase(sl()));
  sl.registerLazySingleton(() => GetLaporanPeriodeUseCase(sl()));
  sl.registerLazySingleton(() => BayarSppUseCase(sl()));
  sl.registerLazySingleton(() => BayarMultipleSppUseCase(sl()));
  sl.registerLazySingleton(() => BayarOnlineSppUseCase(sl()));
  sl.registerFactory(
    () => KeuanganBloc(
      getPembayaranList: sl(),
      getPembayaranBySiswa: sl(),
      getStatusPembayaran: sl(),
      getTunggakan: sl(),
      getTarifByKelas: sl(),
      getLaporanPeriode: sl(),
      bayarOnline: sl(),
      bayarMultiple: sl(),
    ),
  );
  sl.registerFactory(
    () => KeuanganDetailBloc(
      getPembayaranDetail: sl(),
      hitungDenda: sl(),
      bayarOnline: sl(),
      bayarSpp: sl(),
    ),
  );

  // ── Profil feature ────────────────────────────────────────────────────────
  sl.registerLazySingleton<ProfilRemoteDataSource>(
    () => ProfilRemoteDataSourceImpl(sl<ApiClient>().dio),
  );
  sl.registerLazySingleton<ProfilLocalDataSource>(
    () => const ProfilLocalDataSourceImpl(),
  );
  sl.registerLazySingleton<ProfilRepository>(
    () => ProfilRepositoryImpl(sl(), sl()),
  );
  sl.registerLazySingleton(() => GetSekolahAktifUseCase(sl()));
  sl.registerLazySingleton(() => GetPerangkatUserUseCase(sl()));
  sl.registerLazySingleton(() => GetAppInfoUseCase(sl()));
  sl.registerFactory(
    () => ProfilBloc(
      getSekolahAktif: sl(),
      getPerangkatUser: sl(),
      getAppInfo: sl(),
    ),
  );

  // ── Materi feature ────────────────────────────────────────────────────────
  sl.registerLazySingleton<MateriRemoteDataSource>(
    () => MateriRemoteDataSourceImpl(sl<ApiClient>().dio),
  );
  sl.registerLazySingleton<MateriRepository>(() => MateriRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetMateriListUseCase(sl()));
  sl.registerLazySingleton(() => GetMateriDetailUseCase(sl()));
  sl.registerLazySingleton(() => GetMateriByGuruMapelUseCase(sl()));
  sl.registerLazySingleton(() => GetMateriPopulerUseCase(sl()));
  sl.registerLazySingleton(() => CreateMateriUseCase(sl()));
  sl.registerLazySingleton(() => UpdateMateriUseCase(sl()));
  sl.registerLazySingleton(() => DeleteMateriUseCase(sl()));
  sl.registerLazySingleton(() => GetStatistikMateriUseCase(sl()));
  sl.registerLazySingleton(() => GetLogAksesBySiswaUseCase(sl()));
  sl.registerLazySingleton(() => CatatAksesMateriUseCase(sl()));
  sl.registerLazySingleton(() => UpdateDurasiBacaUseCase(sl()));
  sl.registerFactory(
    () => MateriBloc(
      getMateriList: sl(),
      getMateriByGuruMapel: sl(),
      getMateriPopuler: sl(),
    ),
  );
  sl.registerFactory(
    () => MateriDetailBloc(
      getMateriDetail: sl(),
      getStatistikMateri: sl(),
      catatAkses: sl(),
      updateDurasi: sl(),
    ),
  );

  // ── Forum feature ─────────────────────────────────────────────────────────
  sl.registerLazySingleton<ForumRemoteDataSource>(
    () => ForumRemoteDataSourceImpl(sl<ApiClient>().dio),
  );
  sl.registerLazySingleton<ForumRepository>(() => ForumRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetForumListUseCase(sl()));
  sl.registerLazySingleton(() => GetForumDetailUseCase(sl()));
  sl.registerLazySingleton(() => GetForumByUserUseCase(sl()));
  sl.registerLazySingleton(() => CreateForumUseCase(sl()));
  sl.registerLazySingleton(() => UpdateForumUseCase(sl()));
  sl.registerLazySingleton(() => DeleteForumUseCase(sl()));
  sl.registerFactory(
    () => ForumBloc(
      getForumList: sl(),
      createForum: sl(),
      updateForum: sl(),
      deleteForum: sl(),
    ),
  );
  sl.registerFactory(() => ForumDetailBloc(getForumDetail: sl()));

  // ── Ekstrakurikuler feature ───────────────────────────────────────────────
  sl.registerLazySingleton<EkstrakurikulerRemoteDataSource>(
    () => EkstrakurikulerRemoteDataSourceImpl(sl<ApiClient>().dio),
  );
  sl.registerLazySingleton<EkstrakurikulerRepository>(
    () => EkstrakurikulerRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => GetEkstrakurikulerAktifUseCase(sl()));
  sl.registerLazySingleton(() => GetEkstrakurikulerListUseCase(sl()));
  sl.registerLazySingleton(() => GetEkstrakurikulerDetailUseCase(sl()));
  sl.registerLazySingleton(() => GetEkstrakurikulerStatistikUseCase(sl()));
  sl.registerLazySingleton(() => GetEkstrakurikulerByPembinaUseCase(sl()));
  sl.registerLazySingleton(() => GetPesertaEkstrakurikulerUseCase(sl()));
  sl.registerLazySingleton(() => GetPendaftaranSiswaUseCase(sl()));
  sl.registerLazySingleton(() => GetRiwayatPendaftaranSiswaUseCase(sl()));
  sl.registerLazySingleton(() => GetPendaftaranListUseCase(sl()));
  sl.registerLazySingleton(() => CheckStatusPendaftaranUseCase(sl()));
  sl.registerLazySingleton(() => DaftarEkstrakurikulerUseCase(sl()));
  sl.registerLazySingleton(() => KeluarEkstrakurikulerUseCase(sl()));
  sl.registerFactory(
    () => EkstrakurikulerBloc(
      getEkstrakurikulerAktif: sl(),
      getEkstrakurikulerList: sl(),
      getEkstrakurikulerByPembina: sl(),
      getPendaftaranSiswa: sl(),
      getRiwayatPendaftaranSiswa: sl(),
      getPendaftaranList: sl(),
      daftarEkstrakurikuler: sl(),
      keluarEkstrakurikuler: sl(),
    ),
  );
  sl.registerFactory(
    () => EkstrakurikulerDetailBloc(
      getEkstrakurikulerDetail: sl(),
      getEkstrakurikulerStatistik: sl(),
      getPesertaEkstrakurikuler: sl(),
      checkStatusPendaftaran: sl(),
    ),
  );

  // ── Kalender feature ──────────────────────────────────────────────────────
  sl.registerLazySingleton<KalenderRemoteDataSource>(
    () => KalenderRemoteDataSourceImpl(sl<ApiClient>().dio),
  );
  sl.registerLazySingleton<KalenderRepository>(
    () => KalenderRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => GetKalenderEventsUseCase(sl()));
  sl.registerLazySingleton(() => GetKalenderHarianUseCase(sl()));
  sl.registerLazySingleton(() => GetKalenderTipeUseCase(sl()));
  sl.registerLazySingleton(() => GetKalenderKonteksUseCase(sl()));
  sl.registerFactory(
    () => KalenderBloc(
      getEvents: sl(),
      getHarian: sl(),
      getTipe: sl(),
      getKonteks: sl(),
    ),
  );

  // ── BK (Bimbingan Konseling) feature ──────────────────────────────────────
  sl.registerLazySingleton<BkRemoteDataSource>(
    () => BkRemoteDataSourceImpl(sl<ApiClient>().dio),
  );
  sl.registerLazySingleton<BkRepository>(() => BkRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetBkKasusListUseCase(sl()));
  sl.registerLazySingleton(() => GetBkKasusBySiswaUseCase(sl()));
  sl.registerLazySingleton(() => GetBkSesiByKasusUseCase(sl()));
  sl.registerLazySingleton(() => GetBkHasilByKasusUseCase(sl()));
  sl.registerLazySingleton(() => GetBkTindakanByKasusUseCase(sl()));
  sl.registerLazySingleton(() => GetBkJenisListUseCase(sl()));
  sl.registerLazySingleton(() => SearchBkSiswaUseCase(sl()));
  sl.registerLazySingleton(() => CreateBkKasusUseCase(sl()));
  sl.registerLazySingleton(() => CreateBkSesiUseCase(sl()));
  sl.registerLazySingleton(() => CreateBkHasilUseCase(sl()));
  sl.registerLazySingleton(() => CreateBkTindakanUseCase(sl()));
  sl.registerFactory(() => BkBloc(getKasusList: sl(), getKasusBySiswa: sl()));
  sl.registerFactory(
    () => BkDetailBloc(
      getSesiByKasus: sl(),
      getHasilByKasus: sl(),
      getTindakanByKasus: sl(),
      createSesi: sl(),
      createHasil: sl(),
      createTindakan: sl(),
    ),
  );
  sl.registerFactory(
    () => BkFormBloc(getJenisList: sl(), searchSiswa: sl(), createKasus: sl()),
  );

  // ── Ujian + Ranking feature ───────────────────────────────────────────────
  sl.registerLazySingleton<UjianRemoteDataSource>(
    () => UjianRemoteDataSourceImpl(sl<ApiClient>().dio),
  );
  sl.registerLazySingleton<UjianRepository>(
    () => UjianRepositoryImpl(sl(), sl()),
  );
  sl.registerLazySingleton(() => GetUjianByKelasUseCase(sl()));
  sl.registerLazySingleton(() => ujian_uc.GetNilaiUjianUseCase(sl()));
  sl.registerLazySingleton(() => GetRankingKelasUseCase(sl()));
  sl.registerLazySingleton(() => GetKelasOptionsUseCase(sl()));
  sl.registerLazySingleton(() => GenerateRankingUseCase(sl()));
  sl.registerLazySingleton(() => ExportRankingUseCase(sl()));
  sl.registerFactory(
    () => UjianBloc(
      getUjianByKelas: sl(),
      getRankingKelas: sl(),
      getKelasOptions: sl(),
      generateRanking: sl(),
      exportRanking: sl(),
    ),
  );
  sl.registerFactory(() => UjianNilaiBloc(getNilaiUjian: sl()));

  // ── TMB (Tes Minat Bakat) feature ─────────────────────────────────────────
  sl.registerLazySingleton<TmbRemoteDataSource>(
    () => TmbRemoteDataSourceImpl(sl<ApiClient>().dio),
  );
  sl.registerLazySingleton<TmbRepository>(() => TmbRepositoryImpl(sl(), sl()));
  sl.registerLazySingleton(() => GetTmbTesListUseCase(sl()));
  sl.registerLazySingleton(() => GetTmbTesByKelasUseCase(sl()));
  sl.registerLazySingleton(() => GetTmbPertanyaanUseCase(sl()));
  sl.registerLazySingleton(() => GetTmbPesertaBySiswaUseCase(sl()));
  sl.registerLazySingleton(() => GetTmbPesertaByTesUseCase(sl()));
  sl.registerLazySingleton(() => DaftarTmbPesertaUseCase(sl()));
  sl.registerLazySingleton(() => MulaiTmbUseCase(sl()));
  sl.registerLazySingleton(() => SelesaikanTmbUseCase(sl()));
  sl.registerLazySingleton(() => KirimTmbJawabanUseCase(sl()));
  sl.registerLazySingleton(() => GetTmbJawabanByPesertaUseCase(sl()));
  sl.registerLazySingleton(() => GetTmbHasilByPesertaUseCase(sl()));
  sl.registerFactory(
    () => TmbBloc(
      getTesList: sl(),
      getTesByKelas: sl(),
      getPesertaBySiswa: sl(),
      daftarPeserta: sl(),
    ),
  );
  sl.registerFactory(
    () => TmbPengerjaanBloc(
      mulaiTes: sl(),
      getPertanyaan: sl(),
      getJawabanByPeserta: sl(),
      kirimJawaban: sl(),
      selesaikanTes: sl(),
    ),
  );
  sl.registerFactory(() => TmbPesertaBloc(getPesertaByTes: sl()));
  sl.registerFactory(
    () => TmbHasilBloc(getHasilByPeserta: sl(), getPesertaBySiswa: sl()),
  );

  // ── EWS (Early Warning System) feature ────────────────────────────────────
  sl.registerLazySingleton<EwsRemoteDataSource>(
    () => EwsRemoteDataSourceImpl(sl<ApiClient>().dio),
  );
  sl.registerLazySingleton<EwsRepository>(() => EwsRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetEwsAlertsUseCase(sl()));
  sl.registerLazySingleton(() => GetEwsAlertDetailUseCase(sl()));
  sl.registerLazySingleton(() => ResolveEwsAlertUseCase(sl()));
  sl.registerLazySingleton(() => TriggerEwsCheckUseCase(sl()));
  sl.registerFactory(
    () => EwsBloc(getAlerts: sl(), resolveAlert: sl(), triggerCheck: sl()),
  );

  // ── Siswa Insight feature ──────────────────────────────────────────────────
  sl.registerLazySingleton<SiswaInsightRemoteDataSource>(
    () => SiswaInsightRemoteDataSourceImpl(sl<ApiClient>().dio),
  );
  sl.registerLazySingleton<SiswaInsightRepository>(
    () => SiswaInsightRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => GetSiswaInsightUseCase(sl()));
  sl.registerLazySingleton(() => GetSiswaRiskProfileUseCase(sl()));
  sl.registerLazySingleton(() => InvalidateSiswaInsightCacheUseCase(sl()));
  sl.registerFactory(
    () => SiswaInsightBloc(getInsight: sl(), invalidateCache: sl()),
  );
}
