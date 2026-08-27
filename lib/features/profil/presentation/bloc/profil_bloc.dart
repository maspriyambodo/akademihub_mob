import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/app_info_entity.dart';
import '../../domain/entities/perangkat_entity.dart';
import '../../domain/entities/sekolah_entity.dart';
import '../../domain/usecases/get_app_info_usecase.dart';
import '../../domain/usecases/get_perangkat_usecase.dart';
import '../../domain/usecases/get_sekolah_usecase.dart';

part 'profil_event.dart';
part 'profil_state.dart';

/// Bloc ini HANYA mengurus data pelengkap profil (sekolah, perangkat, versi
/// aplikasi). Data user sendiri sudah tersedia di `AuthBloc`, jadi tidak
/// dipanggil ulang ke `/auth/me`.
class ProfilBloc extends Bloc<ProfilEvent, ProfilState> {
  final GetSekolahAktifUseCase getSekolahAktif;
  final GetPerangkatUserUseCase getPerangkatUser;
  final GetAppInfoUseCase getAppInfo;

  // Parameter permintaan terakhir, dipakai ulang saat refresh.
  int? _userId;
  bool _bisaLihatSekolah = false;
  bool _bisaLihatPerangkat = false;

  ProfilBloc({
    required this.getSekolahAktif,
    required this.getPerangkatUser,
    required this.getAppInfo,
  }) : super(ProfilInitial()) {
    on<ProfilLoadRequested>(_onLoad);
    on<ProfilRefreshRequested>(_onRefresh);
  }

  Future<void> _onLoad(
    ProfilLoadRequested event,
    Emitter<ProfilState> emit,
  ) async {
    _userId = event.userId;
    _bisaLihatSekolah = event.bisaLihatSekolah;
    _bisaLihatPerangkat = event.bisaLihatPerangkat;
    emit(ProfilLoading());
    await _muat(emit);
  }

  Future<void> _onRefresh(
    ProfilRefreshRequested event,
    Emitter<ProfilState> emit,
  ) async {
    if (_userId == null) return;
    emit(ProfilLoading());
    await _muat(emit);
  }

  Future<void> _muat(Emitter<ProfilState> emit) async {
    try {
      SekolahEntity? sekolah;
      var sekolahDariCache = false;
      String? sekolahError;

      if (_bisaLihatSekolah) {
        final result = await getSekolahAktif();
        if (result.isSuccess) {
          sekolah = result.requireData;
        } else {
          sekolahError = result.requireFailure.message;
        }
      }

      // 2. Perangkat login (hanya untuk user dengan permission users.view).
      var perangkat = const <PerangkatEntity>[];
      String? perangkatError;
      if (_bisaLihatPerangkat && _userId != null) {
        final result = await getPerangkatUser(_userId!);
        if (result.isSuccess) {
          perangkat = result.requireData;
        } else {
          perangkatError = result.requireFailure.message;
        }
      }

      // 3. Info aplikasi.
      final appResult = await getAppInfo();
      final appInfo = appResult.isSuccess ? appResult.requireData : null;

      emit(
        ProfilLoaded(
          sekolah: sekolah,
          sekolahDariCache: sekolahDariCache,
          sekolahError: sekolahError,
          perangkat: perangkat,
          perangkatTersedia: _bisaLihatPerangkat,
          perangkatError: perangkatError,
          appInfo: appInfo,
        ),
      );
    } catch (e) {
      emit(ProfilError('Gagal memuat data profil: $e'));
    }
  }
}
