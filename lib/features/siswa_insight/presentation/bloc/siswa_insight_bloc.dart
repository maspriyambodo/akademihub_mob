import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/siswa_insight_entity.dart';
import '../../domain/usecases/get_siswa_insight_usecase.dart';
import '../../domain/usecases/invalidate_siswa_insight_cache_usecase.dart';

part 'siswa_insight_event.dart';
part 'siswa_insight_state.dart';

class SiswaInsightBloc extends Bloc<SiswaInsightEvent, SiswaInsightState> {
  final GetSiswaInsightUseCase getInsight;
  final InvalidateSiswaInsightCacheUseCase invalidateCache;

  SiswaInsightBloc({
    required this.getInsight,
    required this.invalidateCache,
  }) : super(const SiswaInsightInitial()) {
    on<InsightLoadRequested>(_onLoad);
    on<InsightRefreshRequested>(_onRefresh);
    on<InsightTabChanged>(_onTabChanged);
    on<InsightInvalidateCacheRequested>(_onInvalidate);
  }

  Future<void> _onLoad(
    InsightLoadRequested event,
    Emitter<SiswaInsightState> emit,
  ) async {
    emit(const SiswaInsightLoading());
    final result = await getInsight(event.siswaId);
    if (isClosed) return;
    if (result.isSuccess) {
      emit(SiswaInsightLoaded(siswaId: event.siswaId, insight: result.requireData));
    } else {
      emit(SiswaInsightError(result.requireFailure.message));
    }
  }

  Future<void> _onRefresh(
    InsightRefreshRequested event,
    Emitter<SiswaInsightState> emit,
  ) async {
    final current = state;
    if (current is! SiswaInsightLoaded) return;
    final result = await getInsight(current.siswaId, refresh: true);
    if (isClosed) return;
    if (result.isSuccess) {
      emit(
        current.copyWith(
          insight: result.requireData,
          actionMessage: null,
        ),
      );
    } else {
      emit(
        current.copyWith(
          actionMessage: result.requireFailure.message,
        ),
      );
    }
  }

  void _onTabChanged(
    InsightTabChanged event,
    Emitter<SiswaInsightState> emit,
  ) {
    final current = state;
    if (current is SiswaInsightLoaded) {
      emit(current.copyWith(activeTab: event.tab));
    }
  }

  Future<void> _onInvalidate(
    InsightInvalidateCacheRequested event,
    Emitter<SiswaInsightState> emit,
  ) async {
    final current = state;
    if (current is! SiswaInsightLoaded) return;
    final result = await invalidateCache(current.siswaId);
    if (isClosed) return;
    if (result.isSuccess) {
      emit(current.copyWith(actionMessage: 'Cache berhasil di-refresh'));
      add(const InsightRefreshRequested());
    } else {
      emit(current.copyWith(actionMessage: result.requireFailure.message));
    }
  }
}
