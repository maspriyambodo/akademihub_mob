part of 'rapor_bloc.dart';

abstract class RaporState extends Equatable {
  const RaporState();
  @override
  List<Object?> get props => [];
}

class RaporInitial extends RaporState {}

class RaporLoading extends RaporState {}

class RaporLoaded extends RaporState {
  final List<RaporEntity> items;
  final String role;
  final String search;

  /// true bila daftar berisi rapor milik satu siswa saja.
  final bool isSiswaMode;
  final bool canCreate;
  final bool canUpdate;
  final bool canDelete;

  const RaporLoaded({
    required this.items,
    required this.role,
    required this.search,
    required this.isSiswaMode,
    required this.canCreate,
    required this.canUpdate,
    required this.canDelete,
  });

  @override
  List<Object?> get props => [
    items,
    role,
    search,
    isSiswaMode,
    canCreate,
    canUpdate,
    canDelete,
  ];
}

class RaporError extends RaporState {
  final String message;
  const RaporError(this.message);

  @override
  List<Object?> get props => [message];
}

class RaporActionSuccess extends RaporState {
  final String message;
  const RaporActionSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

class RaporActionFailure extends RaporState {
  final String message;
  const RaporActionFailure(this.message);
  @override
  List<Object?> get props => [message];
}
