part of 'pengumpulan_bloc.dart';

abstract class PengumpulanState extends Equatable {
  const PengumpulanState();
  @override
  List<Object?> get props => [];
}

class PengumpulanInitial extends PengumpulanState {}

class PengumpulanLoading extends PengumpulanState {}

class PengumpulanLoaded extends PengumpulanState {
  final List<TugasSiswaEntity> items;
  final int totalDinilai;
  final int totalBelumDinilai;

  const PengumpulanLoaded({
    required this.items,
    required this.totalDinilai,
    required this.totalBelumDinilai,
  });

  @override
  List<Object?> get props => [items, totalDinilai, totalBelumDinilai];
}

class PengumpulanError extends PengumpulanState {
  final String message;
  const PengumpulanError(this.message);

  @override
  List<Object?> get props => [message];
}

class PengumpulanActionSuccess extends PengumpulanState {
  final String message;
  const PengumpulanActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class PengumpulanActionFailure extends PengumpulanState {
  final String message;
  const PengumpulanActionFailure(this.message);

  @override
  List<Object?> get props => [message];
}
