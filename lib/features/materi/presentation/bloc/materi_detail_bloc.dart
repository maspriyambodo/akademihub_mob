import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/log_akses_materi_entity.dart';
import '../../domain/entities/materi_entity.dart';
import '../../domain/usecases/get_materi_usecase.dart';
import '../../domain/usecases/log_akses_materi_usecase.dart';

part 'materi_detail_event.dart';
part 'materi_detail_state.dart';

/// Bloc untuk halaman detail materi.
///
/// Catatan: bloc ini TIDAK menangani pencatatan log akses. Pencatatan
/// (`POST /log-akses-materi` + `PUT /{id}/durasi`) dilakukan fire-and-forget
/// langsung di `MateriDetailPage` agar kegagalannya tak pernah memengaruhi UI
/// dan tetap terkirim saat halaman ditutup.
class MateriDetailBloc extends Bloc<MateriDetailEvent, MateriDetailState> {
  final GetMateriDetailUseCase getMateriDetail;
  final GetStatistikMateriUseCase getStatistikMateri;

  int? _materiId;
  MateriEntity? _awal;
  bool _denganStatistik = false;

  MateriDetailBloc({
    required this.getMateriDetail,
    required this.getStatistikMateri,
  }) : super(MateriDetailInitial()) {
    on<MateriDetailLoadRequested>(_onLoad);
    on<MateriDetailRefreshRequested>(_onRefresh);
  }

  Future<void> _onLoad(
    MateriDetailLoadRequested event,
    Emitter<MateriDetailState> emit,
  ) async {
    _materiId = event.materiId;
    _awal = event.awal;
    _denganStatistik = event.denganStatistik;

    // Tampilkan data dari daftar lebih dulu supaya halaman tidak berkedip.
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

  Future<void> _muat(Emitter<MateriDetailState> emit) async {
    final materiId = _materiId;
    if (materiId == null) return;

    final hasil = await getMateriDetail(materiId);

    MateriEntity? materi;
    if (hasil.isSuccess) {
      materi = hasil.requireData;
    } else if (_awal != null) {
      // Detail gagal tapi data dari daftar masih layak ditampilkan.
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
}
