part of 'tmb_peserta_bloc.dart';

abstract class TmbPesertaState extends Equatable {
  const TmbPesertaState();

  @override
  List<Object?> get props => [];
}

class TmbPesertaInitial extends TmbPesertaState {}

class TmbPesertaLoading extends TmbPesertaState {}

class TmbPesertaNoAccess extends TmbPesertaState {
  final String message;
  const TmbPesertaNoAccess(this.message);

  @override
  List<Object?> get props => [message];
}

class TmbPesertaError extends TmbPesertaState {
  final String message;
  const TmbPesertaError(this.message);

  @override
  List<Object?> get props => [message];
}

class TmbPesertaLoaded extends TmbPesertaState {
  final List<TmbPesertaEntity> pesertaList;
  const TmbPesertaLoaded(this.pesertaList);

  int get jumlahSelesai =>
      pesertaList.where((p) => p.isSelesai).length;

  @override
  List<Object?> get props => [pesertaList];
}
