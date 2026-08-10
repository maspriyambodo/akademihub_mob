part of 'siswa_insight_bloc.dart';

abstract class SiswaInsightState extends Equatable {
  const SiswaInsightState();
  @override
  List<Object?> get props => [];
}

class SiswaInsightInitial extends SiswaInsightState {
  const SiswaInsightInitial();
}

class SiswaInsightLoading extends SiswaInsightState {
  const SiswaInsightLoading();
}

class SiswaInsightLoaded extends SiswaInsightState {
  final int siswaId;
  final SiswaInsightEntity insight;
  final int activeTab;
  final String? actionMessage;

  const SiswaInsightLoaded({
    required this.siswaId,
    required this.insight,
    this.activeTab = 0,
    this.actionMessage,
  });

  SiswaInsightLoaded copyWith({
    SiswaInsightEntity? insight,
    int? activeTab,
    String? actionMessage,
  }) {
    return SiswaInsightLoaded(
      siswaId: siswaId,
      insight: insight ?? this.insight,
      activeTab: activeTab ?? this.activeTab,
      actionMessage: actionMessage,
    );
  }

  @override
  List<Object?> get props => [siswaId, insight, activeTab, actionMessage];
}

class SiswaInsightError extends SiswaInsightState {
  final String message;
  const SiswaInsightError(this.message);
  @override
  List<Object?> get props => [message];
}
