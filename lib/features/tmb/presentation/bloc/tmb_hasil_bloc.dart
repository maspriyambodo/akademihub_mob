import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/tmb_hasil_entity.dart';
import '../../domain/entities/tmb_peserta_entity.dart';
import '../../domain/usecases/get_tmb_hasil_by_peserta_usecase.dart';
import '../../domain/usecases/get_tmb_peserta_by_siswa_usecase.dart';

part 'tmb_hasil_event.dart';
part 'tmb_hasil_state.dart';

/// Bloc hasil tes satu peserta.
///
/// Sumber utama adalah relasi `hasil.aspek` yang sudah menempel pada entity
/// peserta (dari endpoint by-siswa/by-tes/selesaikan). Penyegaran data:
/// - staf (punya `tes-minat-bakat-hasil.view` dan bukan siswa/wali) memakai
///   `GET /tes-minat-bakat-hasil/peserta/{id}`;
/// - siswa memuat ulang `GET /tes-minat-bakat-peserta/siswa/{siswaId}` lalu
///   mengambil peserta terkait, karena endpoint hasil by-peserta error untuk
///   role siswa/wali di backend (filter memakai kolom `mst_siswa_id` yang
///   tidak ada di tabel peserta).
class TmbHasilBloc extends Bloc<TmbHasilEvent, TmbHasilState> {
  final GetTmbHasilByPesertaUseCase getHasilByPeserta;
  final GetTmbPesertaBySiswaUseCase getPesertaBySiswa;

  TmbPesertaEntity? _peserta;
  bool _viaHasilEndpoint = false;
  int? _siswaIdUntukRefresh;

  TmbHasilBloc({
    required this.getHasilByPeserta,
    required this.getPesertaBySiswa,
  }) : super(TmbHasilInitial()) {
    on<TmbHasilStarted>(_onStarted);
    on<TmbHasilRefreshRequested>(_onRefresh);
  }

  Future<void> _onStarted(
    TmbHasilStarted event,
    Emitter<TmbHasilState> emit,
  ) async {
    _peserta = event.peserta;
    _viaHasilEndpoint = event.viaHasilEndpoint;
    _siswaIdUntukRefresh = event.siswaIdUntukRefresh;

    if (event.peserta.hasil.isNotEmpty) {
      emit(_loadedDari(event.peserta));
      return;
    }

    emit(TmbHasilLoading());
    await _muatUlang(emit, tampilkanErrorPenuh: true);
  }

  Future<void> _onRefresh(
    TmbHasilRefreshRequested event,
    Emitter<TmbHasilState> emit,
  ) async {
    if (_peserta == null) return;
    await _muatUlang(emit, tampilkanErrorPenuh: state is! TmbHasilLoaded);
  }

  Future<void> _muatUlang(
    Emitter<TmbHasilState> emit, {
    required bool tampilkanErrorPenuh,
  }) async {
    final peserta = _peserta!;

    if (_viaHasilEndpoint) {
      final result = await getHasilByPeserta(peserta.id);
      if (result.isFailure) {
        _emitGagal(emit, result.requireFailure.message, tampilkanErrorPenuh);
        return;
      }
      _peserta = peserta.copyWith(hasil: result.requireData);
      emit(_loadedDari(_peserta!));
      return;
    }

    final siswaId = _siswaIdUntukRefresh;
    if (siswaId == null) {
      // Tidak ada jalur penyegaran yang aman — tampilkan data yang ada.
      emit(_loadedDari(peserta));
      return;
    }

    final result = await getPesertaBySiswa(siswaId);
    if (result.isFailure) {
      _emitGagal(emit, result.requireFailure.message, tampilkanErrorPenuh);
      return;
    }

    for (final p in result.requireData) {
      if (p.id == peserta.id) {
        _peserta = p;
        break;
      }
    }
    emit(_loadedDari(_peserta!));
  }

  void _emitGagal(
    Emitter<TmbHasilState> emit,
    String message,
    bool tampilkanErrorPenuh,
  ) {
    if (tampilkanErrorPenuh) {
      emit(TmbHasilError(message));
    } else {
      emit(_loadedDari(_peserta!));
    }
  }

  TmbHasilLoaded _loadedDari(TmbPesertaEntity peserta) {
    final hasil = List<TmbHasilEntity>.from(peserta.hasil)
      ..sort((a, b) {
        final pa = a.skorPersen ?? a.skorTotal;
        final pb = b.skorPersen ?? b.skorTotal;
        return pb.compareTo(pa);
      });
    return TmbHasilLoaded(
      peserta: peserta,
      hasil: List<TmbHasilEntity>.unmodifiable(hasil),
    );
  }
}
