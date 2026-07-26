part of 'buku_detail_bloc.dart';

abstract class BukuDetailState extends Equatable {
  const BukuDetailState();
  @override
  List<Object?> get props => [];
}

class BukuDetailInitial extends BukuDetailState {}

class BukuDetailLoading extends BukuDetailState {}

class BukuDetailLoaded extends BukuDetailState {
  final BukuEntity buku;

  /// `null` bila pengguna tidak berhak atau permintaannya gagal.
  final BukuRiwayatEntity? riwayat;

  /// Pesan error khusus bagian riwayat (detail buku tetap tampil).
  final String? riwayatError;

  final bool riwayatDiminta;

  const BukuDetailLoaded({
    required this.buku,
    this.riwayat,
    this.riwayatError,
    this.riwayatDiminta = false,
  });

  /// "3 dari 5 tersedia" hanya bisa dihitung bila riwayat peminjaman aktif
  /// berhasil diambil (backend tidak mengirim total eksemplar di `BukuResource`).
  int? get totalEksemplar => riwayat?.totalEksemplar;

  @override
  List<Object?> get props => [buku, riwayat, riwayatError, riwayatDiminta];
}

class BukuDetailError extends BukuDetailState {
  final String message;
  const BukuDetailError(this.message);

  @override
  List<Object?> get props => [message];
}
