part of 'nilai_bloc.dart';

abstract class NilaiEvent extends Equatable {
  const NilaiEvent();
  @override
  List<Object?> get props => [];
}

class NilaiLoadRequested extends NilaiEvent {
  final String role;
  final int? profileId;

  const NilaiLoadRequested({required this.role, this.profileId});

  @override
  List<Object?> get props => [role, profileId];
}

class NilaiRefreshRequested extends NilaiEvent {
  const NilaiRefreshRequested();
}

class NilaiSearchChanged extends NilaiEvent {
  final String query;
  const NilaiSearchChanged(this.query);

  @override
  List<Object?> get props => [query];
}

/// [semester] null berarti "semua semester".
class NilaiSemesterChanged extends NilaiEvent {
  final String? semester;
  const NilaiSemesterChanged(this.semester);

  @override
  List<Object?> get props => [semester];
}

/// [ujianId] null berarti kembali ke daftar nilai umum.
class NilaiUjianSelected extends NilaiEvent {
  final int? ujianId;
  const NilaiUjianSelected(this.ujianId);

  @override
  List<Object?> get props => [ujianId];
}

class NilaiCreateRequested extends NilaiEvent {
  final int siswaId;
  final int ujianId;
  final double nilai;
  final String? keterangan;
  const NilaiCreateRequested({required this.siswaId, required this.ujianId, required this.nilai, this.keterangan});
  @override
  List<Object?> get props => [siswaId, ujianId, nilai, keterangan];
}

class NilaiUpdateRequested extends NilaiEvent {
  final int id;
  final double nilai;
  final String? keterangan;
  const NilaiUpdateRequested({required this.id, required this.nilai, this.keterangan});
  @override
  List<Object?> get props => [id, nilai, keterangan];
}

class NilaiDeleteRequested extends NilaiEvent {
  final int id;
  const NilaiDeleteRequested(this.id);
  @override
  List<Object?> get props => [id];
}
