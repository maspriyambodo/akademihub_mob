import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/ujian_nilai_entity.dart';
import '../../domain/usecases/get_nilai_ujian_usecase.dart';

part 'ujian_nilai_event.dart';
part 'ujian_nilai_state.dart';

/// Bloc halaman daftar nilai satu ujian (`GET /akademik/ujian/{id}/nilai`).
class UjianNilaiBloc extends Bloc<UjianNilaiEvent, UjianNilaiState> {
  final GetNilaiUjianUseCase getNilaiUjian;

  int? _ujianId;

  UjianNilaiBloc({required this.getNilaiUjian}) : super(UjianNilaiInitial()) {
    on<UjianNilaiLoadRequested>(_onLoad);
    on<UjianNilaiRefreshRequested>(_onRefresh);
  }

  Future<void> _onLoad(
    UjianNilaiLoadRequested event,
    Emitter<UjianNilaiState> emit,
  ) async {
    _ujianId = event.ujianId;
    emit(UjianNilaiLoading());
    await _fetch(emit);
  }

  Future<void> _onRefresh(
    UjianNilaiRefreshRequested event,
    Emitter<UjianNilaiState> emit,
  ) async {
    if (_ujianId == null) return;
    await _fetch(emit);
  }

  Future<void> _fetch(Emitter<UjianNilaiState> emit) async {
    final result = await getNilaiUjian(_ujianId!);
    if (result.isSuccess) {
      emit(UjianNilaiLoaded(result.requireData));
    } else {
      emit(UjianNilaiError(result.requireFailure.message));
    }
  }
}
