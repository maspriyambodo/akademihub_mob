part of 'tmb_peserta_bloc.dart';

abstract class TmbPesertaEvent extends Equatable {
  const TmbPesertaEvent();

  @override
  List<Object?> get props => [];
}

class TmbPesertaLoadRequested extends TmbPesertaEvent {
  final int tesId;
  const TmbPesertaLoadRequested(this.tesId);

  @override
  List<Object?> get props => [tesId];
}

class TmbPesertaRefreshRequested extends TmbPesertaEvent {
  const TmbPesertaRefreshRequested();
}
