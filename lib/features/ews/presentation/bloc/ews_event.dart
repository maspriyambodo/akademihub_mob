part of 'ews_bloc.dart';

abstract class EwsEvent extends Equatable {
  const EwsEvent();
  @override
  List<Object?> get props => [];
}

class EwsLoadRequested extends EwsEvent {
  final String? kategori;
  final int? level;
  final bool? onlyUnresolved;

  const EwsLoadRequested({this.kategori, this.level, this.onlyUnresolved});

  @override
  List<Object?> get props => [kategori, level, onlyUnresolved];
}

class EwsRefreshRequested extends EwsEvent {
  const EwsRefreshRequested();
}

class EwsFilterChanged extends EwsEvent {
  final String? kategori;
  final int? level;
  final bool? onlyUnresolved;

  const EwsFilterChanged({this.kategori, this.level, this.onlyUnresolved});

  @override
  List<Object?> get props => [kategori, level, onlyUnresolved];
}

class EwsResolveRequested extends EwsEvent {
  final int id;
  const EwsResolveRequested(this.id);
  @override
  List<Object?> get props => [id];
}

class EwsTriggerCheckRequested extends EwsEvent {
  final int siswaId;
  const EwsTriggerCheckRequested(this.siswaId);
  @override
  List<Object?> get props => [siswaId];
}
