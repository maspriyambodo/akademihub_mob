part of 'tugas_bloc.dart';

abstract class TugasEvent extends Equatable {
  const TugasEvent();
  @override
  List<Object?> get props => [];
}

class TugasLoadRequested extends TugasEvent {
  final String role;

  /// `profile['id']` bila role siswa.
  final int? siswaId;

  /// `profile['kelas']['id']` bila role siswa.
  final int? kelasId;

  /// `profile['id']` bila role guru (id `mst_guru`).
  final int? guruId;

  /// Id `mst_guru_mapel` bila tersedia di profil (opsional).
  final int? guruMapelId;
  final bool canSubmit;

  const TugasLoadRequested({
    required this.role,
    this.siswaId,
    this.kelasId,
    this.guruId,
    this.guruMapelId,
    this.canSubmit = false,
  });

  @override
  List<Object?> get props => [
    role,
    siswaId,
    kelasId,
    guruId,
    guruMapelId,
    canSubmit,
  ];
}

class TugasRefreshRequested extends TugasEvent {
  const TugasRefreshRequested();
}

class TugasFilterChanged extends TugasEvent {
  final TugasFilter filter;
  const TugasFilterChanged(this.filter);

  @override
  List<Object?> get props => [filter];
}

class TugasSubmitRequested extends TugasEvent {
  final int tugasId;
  final String? jawaban;
  final String? fileJawaban;

  const TugasSubmitRequested({
    required this.tugasId,
    this.jawaban,
    this.fileJawaban,
  });

  @override
  List<Object?> get props => [tugasId, jawaban, fileJawaban];
}
