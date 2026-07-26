part of 'rapor_detail_bloc.dart';

abstract class RaporDetailEvent extends Equatable {
  const RaporDetailEvent();
  @override
  List<Object?> get props => [];
}

class RaporDetailLoadRequested extends RaporDetailEvent {
  final int raporId;
  const RaporDetailLoadRequested(this.raporId);

  @override
  List<Object?> get props => [raporId];
}

class RaporDetailRefreshRequested extends RaporDetailEvent {
  const RaporDetailRefreshRequested();
}

/// Unduh berkas rapor milik [siswaId] (butuh permission `rapor.export`).
class RaporDetailExportRequested extends RaporDetailEvent {
  final int siswaId;
  const RaporDetailExportRequested(this.siswaId);

  @override
  List<Object?> get props => [siswaId];
}
