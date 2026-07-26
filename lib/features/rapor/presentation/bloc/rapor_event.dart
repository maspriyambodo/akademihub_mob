part of 'rapor_bloc.dart';

abstract class RaporEvent extends Equatable {
  const RaporEvent();
  @override
  List<Object?> get props => [];
}

class RaporLoadRequested extends RaporEvent {
  final String role;
  final int? profileId;

  const RaporLoadRequested({required this.role, this.profileId});

  @override
  List<Object?> get props => [role, profileId];
}

class RaporSearchChanged extends RaporEvent {
  final String query;
  const RaporSearchChanged(this.query);

  @override
  List<Object?> get props => [query];
}

class RaporRefreshRequested extends RaporEvent {
  const RaporRefreshRequested();
}
