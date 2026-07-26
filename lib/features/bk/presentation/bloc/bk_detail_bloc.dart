import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/bk_hasil_entity.dart';
import '../../domain/entities/bk_sesi_entity.dart';
import '../../domain/entities/bk_tindakan_entity.dart';
import '../../domain/usecases/create_bk_hasil_usecase.dart';
import '../../domain/usecases/create_bk_sesi_usecase.dart';
import '../../domain/usecases/create_bk_tindakan_usecase.dart';
import '../../domain/usecases/get_bk_kasus_relasi_usecase.dart';

part 'bk_detail_event.dart';
part 'bk_detail_state.dart';

/// Bloc detail kasus: memuat sesi konseling, hasil, dan tindak lanjut lewat
/// endpoint index masing-masing dengan filter `trx_bk_kasus_id` (filter ini
/// diverifikasi ada di `BkSesiService`/`BkHasilService`/`BkTindakanService`).
///
/// Endpoint `GET /bk/kasus/{id}` sengaja TIDAK dipakai: seluruh field kasus
/// sudah tersedia dari daftar, dan endpoint show hanya menambah relasi
/// lampiran. Seksi yang role-nya tidak punya permission view tidak dipanggil
/// sama sekali (backend akan menolak 403).
class BkDetailBloc extends Bloc<BkDetailEvent, BkDetailState> {
  final GetBkSesiByKasusUseCase getSesiByKasus;
  final GetBkHasilByKasusUseCase getHasilByKasus;
  final GetBkTindakanByKasusUseCase getTindakanByKasus;
  final CreateBkSesiUseCase createSesi;
  final CreateBkHasilUseCase createHasil;
  final CreateBkTindakanUseCase createTindakan;

  int _kasusId = 0;
  bool _canViewSesi = false;
  bool _canViewHasil = false;
  bool _canViewTindakan = false;
  bool _canManageSesi = false;
  bool _canManageHasil = false;
  bool _canManageTindakan = false;

  List<BkSesiEntity> _sesi = const [];
  List<BkHasilEntity> _hasil = const [];
  List<BkTindakanEntity> _tindakan = const [];
  String? _errorSesi;
  String? _errorHasil;
  String? _errorTindakan;
  int _revisi = 0;

  BkDetailBloc({
    required this.getSesiByKasus,
    required this.getHasilByKasus,
    required this.getTindakanByKasus,
    required this.createSesi,
    required this.createHasil,
    required this.createTindakan,
  }) : super(BkDetailInitial()) {
    on<BkDetailLoadRequested>(_onLoad);
    on<BkDetailRefreshRequested>(_onRefresh);
    on<BkSesiCreateRequested>(_onCreateSesi);
    on<BkHasilCreateRequested>(_onCreateHasil);
    on<BkTindakanCreateRequested>(_onCreateTindakan);
  }

  Future<void> _onLoad(
    BkDetailLoadRequested event,
    Emitter<BkDetailState> emit,
  ) async {
    _kasusId = event.kasusId;
    _canViewSesi = event.canViewSesi;
    _canViewHasil = event.canViewHasil;
    _canViewTindakan = event.canViewTindakan;
    _canManageSesi = event.canManageSesi;
    _canManageHasil = event.canManageHasil;
    _canManageTindakan = event.canManageTindakan;

    emit(BkDetailLoading());
    await _fetchAndEmit(emit);
  }

  Future<void> _onRefresh(
    BkDetailRefreshRequested event,
    Emitter<BkDetailState> emit,
  ) async {
    if (_kasusId == 0) return;
    await _fetchAndEmit(emit);
  }

  Future<void> _fetchAndEmit(Emitter<BkDetailState> emit) async {
    _errorSesi = null;
    _errorHasil = null;
    _errorTindakan = null;

    if (_canViewSesi) {
      final r = await getSesiByKasus(_kasusId);
      if (r.isSuccess) {
        _sesi = r.requireData;
      } else {
        _sesi = const [];
        _errorSesi = r.requireFailure.message;
      }
    }
    if (_canViewHasil) {
      final r = await getHasilByKasus(_kasusId);
      if (r.isSuccess) {
        _hasil = r.requireData;
      } else {
        _hasil = const [];
        _errorHasil = r.requireFailure.message;
      }
    }
    if (_canViewTindakan) {
      final r = await getTindakanByKasus(_kasusId);
      if (r.isSuccess) {
        _tindakan = r.requireData;
      } else {
        _tindakan = const [];
        _errorTindakan = r.requireFailure.message;
      }
    }

    _revisi++;
    emit(_buildLoaded());
  }

  Future<void> _onCreateSesi(
    BkSesiCreateRequested event,
    Emitter<BkDetailState> emit,
  ) async {
    final result = await createSesi(
      kasusId: _kasusId,
      tanggal: event.tanggal,
      metode: event.metode,
      catatan: event.catatan,
    );
    if (result.isFailure) {
      emit(BkDetailActionFailure(result.requireFailure.message));
      emit(_buildLoaded());
      return;
    }
    emit(const BkDetailActionSuccess('Sesi konseling berhasil dicatat'));
    await _fetchAndEmit(emit);
  }

  Future<void> _onCreateHasil(
    BkHasilCreateRequested event,
    Emitter<BkDetailState> emit,
  ) async {
    final result = await createHasil(
      kasusId: _kasusId,
      hasil: event.hasil,
      rekomendasi: event.rekomendasi,
    );
    if (result.isFailure) {
      emit(BkDetailActionFailure(result.requireFailure.message));
      emit(_buildLoaded());
      return;
    }
    emit(const BkDetailActionSuccess('Hasil konseling berhasil dicatat'));
    await _fetchAndEmit(emit);
  }

  Future<void> _onCreateTindakan(
    BkTindakanCreateRequested event,
    Emitter<BkDetailState> emit,
  ) async {
    final result = await createTindakan(
      kasusId: _kasusId,
      deskripsi: event.deskripsi,
    );
    if (result.isFailure) {
      emit(BkDetailActionFailure(result.requireFailure.message));
      emit(_buildLoaded());
      return;
    }
    emit(const BkDetailActionSuccess('Tindak lanjut berhasil dicatat'));
    await _fetchAndEmit(emit);
  }

  BkDetailLoaded _buildLoaded() => BkDetailLoaded(
    sesi: _sesi,
    hasil: _hasil,
    tindakan: _tindakan,
    errorSesi: _errorSesi,
    errorHasil: _errorHasil,
    errorTindakan: _errorTindakan,
    canViewSesi: _canViewSesi,
    canViewHasil: _canViewHasil,
    canViewTindakan: _canViewTindakan,
    canManageSesi: _canManageSesi,
    canManageHasil: _canManageHasil,
    canManageTindakan: _canManageTindakan,
    revisi: _revisi,
  );
}
