part of 'keuangan_detail_bloc.dart';

abstract class KeuanganDetailEvent extends Equatable {
  const KeuanganDetailEvent();
  @override
  List<Object?> get props => [];
}

class KeuanganDetailLoadRequested extends KeuanganDetailEvent {
  final int pembayaranId;
  const KeuanganDetailLoadRequested(this.pembayaranId);

  @override
  List<Object?> get props => [pembayaranId];
}

class KeuanganDetailRefreshRequested extends KeuanganDetailEvent {
  const KeuanganDetailRefreshRequested();
}

/// Inisiasi pembayaran online Midtrans untuk tagihan yang sedang dibuka.
class KeuanganDetailBayarOnlineRequested extends KeuanganDetailEvent {
  const KeuanganDetailBayarOnlineRequested();
}

/// Catat pelunasan (aksi admin/petugas, butuh `pembayaran-spp.bayar`).
class KeuanganDetailBayarTunaiRequested extends KeuanganDetailEvent {
  /// Kode `sys_references.metode_pembayaran` (1=Tunai, 2=Transfer, 3=VA).
  final int metodePembayaran;
  final String? keterangan;

  const KeuanganDetailBayarTunaiRequested({
    this.metodePembayaran = 1,
    this.keterangan,
  });

  @override
  List<Object?> get props => [metodePembayaran, keterangan];
}
