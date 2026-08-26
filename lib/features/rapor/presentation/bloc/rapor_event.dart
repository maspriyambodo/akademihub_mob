part of 'rapor_bloc.dart';

abstract class RaporEvent extends Equatable {
  const RaporEvent();
  @override
  List<Object?> get props => [];
}

class RaporLoadRequested extends RaporEvent {
  final String role;
  final int? profileId;
  final bool canCreate;
  final bool canUpdate;
  final bool canDelete;

  const RaporLoadRequested({
    required this.role,
    this.profileId,
    this.canCreate = false,
    this.canUpdate = false,
    this.canDelete = false,
  });

  @override
  List<Object?> get props => [role, profileId, canCreate, canUpdate, canDelete];
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

class RaporCreateRequested extends RaporEvent {
  final int siswaId;
  final int semester;
  final String? catatanWali;
  final int sakit;
  final int izin;
  final int tanpaKeterangan;

  const RaporCreateRequested({
    required this.siswaId,
    required this.semester,
    this.catatanWali,
    required this.sakit,
    required this.izin,
    required this.tanpaKeterangan,
  });
}

class RaporUpdateRequested extends RaporEvent {
  final int id;
  final String? catatanWali;
  final int sakit;
  final int izin;
  final int tanpaKeterangan;

  const RaporUpdateRequested({
    required this.id,
    this.catatanWali,
    required this.sakit,
    required this.izin,
    required this.tanpaKeterangan,
  });
}

class RaporDeleteRequested extends RaporEvent {
  final int id;
  const RaporDeleteRequested(this.id);
}
