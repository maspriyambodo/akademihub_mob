import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/tmb_peserta_entity.dart';
import '../../domain/repositories/tmb_repository.dart';
import '../../domain/usecases/get_tmb_peserta_by_tes_usecase.dart';

part 'tmb_peserta_event.dart';
part 'tmb_peserta_state.dart';

/// Bloc daftar peserta satu tes (mode staf, read-only).
///
/// Catatan backend: visibilitas dibatasi per sesi — admin melihat semua,
/// role `guru` hanya siswa perwaliannya, sedangkan role lain (termasuk
/// `guru_bk`) mendapat daftar kosong dari backend.
class TmbPesertaBloc extends Bloc<TmbPesertaEvent, TmbPesertaState> {
  final GetTmbPesertaByTesUseCase getPesertaByTes;

  int? _tesId;

  TmbPesertaBloc({required this.getPesertaByTes}) : super(TmbPesertaInitial()) {
    on<TmbPesertaLoadRequested>(_onLoad);
    on<TmbPesertaRefreshRequested>(_onRefresh);
  }

  Future<void> _onLoad(
    TmbPesertaLoadRequested event,
    Emitter<TmbPesertaState> emit,
  ) async {
    _tesId = event.tesId;
    emit(TmbPesertaLoading());
    await _fetchAndEmit(emit);
  }

  Future<void> _onRefresh(
    TmbPesertaRefreshRequested event,
    Emitter<TmbPesertaState> emit,
  ) async {
    if (_tesId == null) return;
    if (state is! TmbPesertaLoaded) emit(TmbPesertaLoading());
    await _fetchAndEmit(emit);
  }

  Future<void> _fetchAndEmit(Emitter<TmbPesertaState> emit) async {
    final result = await getPesertaByTes(_tesId!);
    if (result.isFailure) {
      final f = result.requireFailure;
      if (f is TmbAccessFailure) {
        emit(TmbPesertaNoAccess(f.message));
      } else {
        emit(TmbPesertaError(f.message));
      }
      return;
    }

    final list = List<TmbPesertaEntity>.from(result.requireData)
      ..sort((a, b) {
        final byNama = (a.siswaNama ?? '').compareTo(b.siswaNama ?? '');
        return byNama != 0 ? byNama : a.id.compareTo(b.id);
      });
    emit(TmbPesertaLoaded(List<TmbPesertaEntity>.unmodifiable(list)));
  }
}
