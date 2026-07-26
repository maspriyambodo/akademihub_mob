part of 'organisasi_bloc.dart';

abstract class OrganisasiEvent extends Equatable {
  const OrganisasiEvent();

  @override
  List<Object?> get props => [];
}

class OrganisasiLoadRequested extends OrganisasiEvent {
  /// Hasil `user.hasPermission('organisasi.view')` — siswa & wali punya,
  /// guru TIDAK (verifikasi RbacSeeder).
  final bool bolehLihat;

  const OrganisasiLoadRequested({required this.bolehLihat});

  @override
  List<Object?> get props => [bolehLihat];
}

class OrganisasiRefreshRequested extends OrganisasiEvent {
  const OrganisasiRefreshRequested();
}

class OrganisasiSearchChanged extends OrganisasiEvent {
  final String query;
  const OrganisasiSearchChanged(this.query);

  @override
  List<Object?> get props => [query];
}

class OrganisasiStatusFilterChanged extends OrganisasiEvent {
  final StatusOrganisasiFilter filter;
  const OrganisasiStatusFilterChanged(this.filter);

  @override
  List<Object?> get props => [filter];
}

class OrganisasiPeriodeFilterChanged extends OrganisasiEvent {
  /// Tahun `periode_mulai` yang dipilih; null = semua periode.
  final int? periode;
  const OrganisasiPeriodeFilterChanged(this.periode);

  @override
  List<Object?> get props => [periode];
}
