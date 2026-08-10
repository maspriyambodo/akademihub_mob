part of 'siswa_insight_bloc.dart';

abstract class SiswaInsightEvent extends Equatable {
  const SiswaInsightEvent();
  @override
  List<Object?> get props => [];
}

class InsightLoadRequested extends SiswaInsightEvent {
  final int siswaId;
  const InsightLoadRequested(this.siswaId);
  @override
  List<Object?> get props => [siswaId];
}

class InsightRefreshRequested extends SiswaInsightEvent {
  const InsightRefreshRequested();
}

class InsightTabChanged extends SiswaInsightEvent {
  final int tab;
  const InsightTabChanged(this.tab);
  @override
  List<Object?> get props => [tab];
}

class InsightInvalidateCacheRequested extends SiswaInsightEvent {
  const InsightInvalidateCacheRequested();
}
