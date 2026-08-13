part of 'tmb_hasil_bloc.dart';

abstract class TmbHasilEvent extends Equatable {
  const TmbHasilEvent();

  @override
  List<Object?> get props => [];
}

class TmbHasilStarted extends TmbHasilEvent {
  final TmbPesertaEntity peserta;

  /// True bila boleh memakai `GET /tes-minat-bakat-hasil/peserta/{id}`
  /// (staf dengan `tes-minat-bakat-hasil.view`; JANGAN untuk siswa/wali —
  /// endpoint itu error untuk mereka di backend).
  final bool viaHasilEndpoint;

  /// Untuk siswa: id siswa agar refresh bisa lewat endpoint peserta by-siswa.
  final int? siswaIdUntukRefresh;

  const TmbHasilStarted({
    required this.peserta,
    this.viaHasilEndpoint = false,
    this.siswaIdUntukRefresh,
  });

  @override
  List<Object?> get props => [
    peserta.id,
    viaHasilEndpoint,
    siswaIdUntukRefresh,
  ];
}

class TmbHasilRefreshRequested extends TmbHasilEvent {
  const TmbHasilRefreshRequested();
}
