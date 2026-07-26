import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/buku_entity.dart';
import '../../domain/entities/buku_riwayat_entity.dart';
import '../../domain/usecases/get_buku_usecase.dart';

part 'buku_detail_event.dart';
part 'buku_detail_state.dart';

class BukuDetailBloc extends Bloc<BukuDetailEvent, BukuDetailState> {
  final GetBukuDetailUseCase getBukuDetail;
  final GetRiwayatBukuUseCase getRiwayatBuku;

  int _bukuId = 0;
  bool _withRiwayat = false;

  BukuDetailBloc({required this.getBukuDetail, required this.getRiwayatBuku})
    : super(BukuDetailInitial()) {
    on<BukuDetailLoadRequested>(_onLoad);
    on<BukuDetailRefreshRequested>(_onRefresh);
  }

  Future<void> _onLoad(
    BukuDetailLoadRequested event,
    Emitter<BukuDetailState> emit,
  ) async {
    _bukuId = event.bukuId;
    _withRiwayat = event.withRiwayat;
    emit(BukuDetailLoading());
    await _fetch(emit);
  }

  Future<void> _onRefresh(
    BukuDetailRefreshRequested event,
    Emitter<BukuDetailState> emit,
  ) async {
    await _fetch(emit);
  }

  Future<void> _fetch(Emitter<BukuDetailState> emit) async {
    final bukuResult = await getBukuDetail(_bukuId);
    if (bukuResult.isFailure) {
      emit(BukuDetailError(bukuResult.requireFailure.message));
      return;
    }

    if (!_withRiwayat) {
      emit(BukuDetailLoaded(buku: bukuResult.requireData));
      return;
    }

    final riwayatResult = await getRiwayatBuku(_bukuId);
    emit(
      BukuDetailLoaded(
        buku: bukuResult.requireData,
        riwayat: riwayatResult.isSuccess ? riwayatResult.requireData : null,
        riwayatError: riwayatResult.isFailure
            ? riwayatResult.requireFailure.message
            : null,
        riwayatDiminta: true,
      ),
    );
  }
}
