part of 'organisasi_detail_bloc.dart';

abstract class OrganisasiDetailEvent extends Equatable {
  const OrganisasiDetailEvent();

  @override
  List<Object?> get props => [];
}

class OrganisasiDetailLoadRequested extends OrganisasiDetailEvent {
  final int organisasiId;
  const OrganisasiDetailLoadRequested(this.organisasiId);

  @override
  List<Object?> get props => [organisasiId];
}

class OrganisasiDetailRefreshRequested extends OrganisasiDetailEvent {
  const OrganisasiDetailRefreshRequested();
}

class OrganisasiDetailSearchChanged extends OrganisasiDetailEvent {
  final String query;
  const OrganisasiDetailSearchChanged(this.query);

  @override
  List<Object?> get props => [query];
}

class OrganisasiDetailStatusFilterChanged extends OrganisasiDetailEvent {
  final StatusAnggotaFilter filter;
  const OrganisasiDetailStatusFilterChanged(this.filter);

  @override
  List<Object?> get props => [filter];
}
