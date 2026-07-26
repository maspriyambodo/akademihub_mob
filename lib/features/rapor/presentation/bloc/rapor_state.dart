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

  const RaporLoaded({
    required this.items,
    required this.role,
    required this.search,
    required this.isSiswaMode,
  });

  @override
  List<Object?> get props => [items, role, search, isSiswaMode];
}

class RaporError extends RaporState {
  final String message;
  const RaporError(this.message);

  @override
  List<Object?> get props => [message];
}
