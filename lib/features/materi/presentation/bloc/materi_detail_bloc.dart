import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/log_akses_materi_entity.dart';
import '../../domain/entities/materi_entity.dart';
import '../../domain/usecases/get_materi_usecase.dart';
import '../../domain/usecases/log_akses_materi_usecase.dart';

part 'materi_detail_event.dart';
part 'materi_detail_state.dart';

/// Bloc halaman detail materi + pencatatan log akses (domain lewat use case).
///
/// Log akses fire-and-forget: kegagalan tidak mengubah state UI.
class MateriDetailBloc extends Bloc<MateriDetailEvent, MateriDetailState> {
  final GetMateriDetailUseCase getMateriDetail;
  final GetStatistikMateriUseCase getStatistikMateri;
  final CatatAksesMateriUseCase catatAkses;
  final UpdateDurasiBacaUseCase updateDurasi;

  int? _materiId;
  MateriEntity? _awal;
  bool _denganStatistik = false;

  Future<int?>? _logIdFuture;

  MateriDetailBloc({
    required this.getMateriDetail,
    required this.getStatistikMateri,
    required this.catatAkses,
    required this.updateDurasi,
  }) : super(MateriDetailInitial()) {
    on<MateriDetailLoadRequested>(_onLoad);
    on<MateriDetailRefreshRequested>(_onRefresh);
    on<MateriDetailAksesDiminta>(_onAksesDiminta);
    on<MateriDetailDurasiDikirim>(_onDurasiDikirim);
  }

  Future<void> _onLoad(
    MateriDetailLoadRequested event,
    Emitter<MateriDetailState> emit,
  ) async {
    _materiId = event.materiId;
    _awal = event.awal;
    _denganStatistik = event.denganStatistik;

    if (_awal != null) {
      emit(MateriDetailLoaded(materi: _awal!));
    } else {
      emit(MateriDetailLoading());
    }

    await _muat(emit);
  }

  Future<void> _onRefresh(
    MateriDetailRefreshRequested event,
    Emitter<MateriDetailState> emit,
  ) async {
    await _muat(emit);
  }

  Future<void> _onAksesDiminta(
    MateriDetailAksesDiminta event,
    Emitter<MateriDetailState> emit,
  ) async {
    _logIdFuture = _kirimCatatAkses(
      materiId: event.materiId,
      siswaId: event.siswaId,
      kelasId: event.kelasId,
    );
  }

  Future<void> _onDurasiDikirim(
    MateriDetailDurasiDikirim event,
    Emitter<MateriDetailState> emit,
  ) async {
    final future = _logIdFuture;
    if (future == null || event.durasiDetik < 0) return;
    unawaited(_prosesKirimDurasi(future, event.durasiDetik));
  }

  Future<void> _muat(Emitter<MateriDetailState> emit) async {
    final materiId = _materiId;
    if (materiId == null) return;

    final hasil = await getMateriDetail(materiId);

    MateriEntity? materi;
    if (hasil.isSuccess) {
      materi = hasil.requireData;
    } else if (_awal != null) {
      materi = _awal;
    }

    if (materi == null) {
      emit(MateriDetailError(hasil.requireFailure.message));
      return;
    }

    emit(MateriDetailLoaded(materi: materi, memuatStatistik: _denganStatistik));

    if (!_denganStatistik) return;

    final statistik = await getStatistikMateri(materiId);
    if (isClosed) return;

    emit(
      MateriDetailLoaded(
        materi: materi,
        statistik: statistik.isSuccess ? statistik.requireData : null,
        statistikGagal: statistik.isFailure,
      ),
    );
  }

  Future<int?> _kirimCatatAkses({
    required int materiId,
    required int siswaId,
    required int kelasId,
  }) async {
    try {
      final hasil = await catatAkses(
        materiId: materiId,
        siswaId: siswaId,
        kelasId: kelasId,
      );
      if (hasil.isFailure) return null;
      final id = hasil.requireData.id;
      return id > 0 ? id : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _prosesKirimDurasi(
    Future<int?> logIdFuture,
    int durasiDetik,
  ) async {
    try {
      final logId = await logIdFuture;
      if (logId == null) return;
      await updateDurasi(logId: logId, durasiDetik: durasiDetik);
    } catch (_) {}
  }
}
