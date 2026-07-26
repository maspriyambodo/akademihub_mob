part of 'buku_detail_bloc.dart';

abstract class BukuDetailEvent extends Equatable {
  const BukuDetailEvent();
  @override
  List<Object?> get props => [];
}

class BukuDetailLoadRequested extends BukuDetailEvent {
  final int bukuId;

  /// Ambil juga `/buku/{id}/peminjaman` (butuh permission `peminjaman.view`).
  final bool withRiwayat;

  const BukuDetailLoadRequested(this.bukuId, {this.withRiwayat = false});

  @override
  List<Object?> get props => [bukuId, withRiwayat];
}

class BukuDetailRefreshRequested extends BukuDetailEvent {
  const BukuDetailRefreshRequested();
}
