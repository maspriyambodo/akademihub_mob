part of 'materi_detail_bloc.dart';

abstract class MateriDetailState extends Equatable {
  const MateriDetailState();

  @override
  List<Object?> get props => [];
}

class MateriDetailInitial extends MateriDetailState {}

class MateriDetailLoading extends MateriDetailState {}

class MateriDetailLoaded extends MateriDetailState {
  final MateriEntity materi;

  /// Statistik pembaca; null bila belum dimuat / tidak diminta / gagal.
  final MateriStatistikEntity? statistik;

  /// True selagi statistik masih dalam perjalanan.
  final bool memuatStatistik;

  /// True bila permintaan statistik gagal (ditampilkan halus, bukan error).
  final bool statistikGagal;

  const MateriDetailLoaded({
    required this.materi,
    this.statistik,
    this.memuatStatistik = false,
    this.statistikGagal = false,
  });

  @override
  List<Object?> get props => [
    materi,
    statistik,
    memuatStatistik,
    statistikGagal,
  ];
}

class MateriDetailError extends MateriDetailState {
  final String message;
  const MateriDetailError(this.message);

  @override
  List<Object?> get props => [message];
}
