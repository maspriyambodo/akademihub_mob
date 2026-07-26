part of 'materi_detail_bloc.dart';

abstract class MateriDetailEvent extends Equatable {
  const MateriDetailEvent();

  @override
  List<Object?> get props => [];
}

class MateriDetailLoadRequested extends MateriDetailEvent {
  final int materiId;

  /// Data materi dari daftar; dipakai sebagai tampilan awal sekaligus
  /// cadangan bila endpoint detail gagal.
  final MateriEntity? awal;

  /// Ambil juga statistik pembaca (hanya guru/admin).
  final bool denganStatistik;

  const MateriDetailLoadRequested({
    required this.materiId,
    this.awal,
    this.denganStatistik = false,
  });

  @override
  List<Object?> get props => [materiId, awal, denganStatistik];
}

class MateriDetailRefreshRequested extends MateriDetailEvent {
  const MateriDetailRefreshRequested();
}
