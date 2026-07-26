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
