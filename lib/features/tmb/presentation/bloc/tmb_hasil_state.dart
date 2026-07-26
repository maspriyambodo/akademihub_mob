part of 'tmb_hasil_bloc.dart';

abstract class TmbHasilState extends Equatable {
  const TmbHasilState();

  @override
  List<Object?> get props => [];
}

class TmbHasilInitial extends TmbHasilState {}

class TmbHasilLoading extends TmbHasilState {}

class TmbHasilError extends TmbHasilState {
  final String message;
  const TmbHasilError(this.message);

  @override
  List<Object?> get props => [message];
}

class TmbHasilLoaded extends TmbHasilState {
  final TmbPesertaEntity peserta;

  /// Hasil per aspek, terurut skor tertinggi lebih dulu.
  final List<TmbHasilEntity> hasil;

  const TmbHasilLoaded({required this.peserta, required this.hasil});

  /// Skor persen tertinggi — dasar skala bar bila `skor_persen` kosong.
  int get skorTotalTertinggi {
    var max = 0;
    for (final h in hasil) {
      if (h.skorTotal > max) max = h.skorTotal;
    }
    return max;
  }

  @override
  List<Object?> get props => [peserta, hasil];
}
