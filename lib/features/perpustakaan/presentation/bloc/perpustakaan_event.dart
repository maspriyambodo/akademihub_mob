part of 'perpustakaan_bloc.dart';

abstract class PerpustakaanEvent extends Equatable {
  const PerpustakaanEvent();
  @override
  List<Object?> get props => [];
}

/// Dipanggil sekali dari `initState` setelah state `AuthBloc` terbaca.
class PerpustakaanLoadRequested extends PerpustakaanEvent {
  /// 'siswa' | 'guru' | 'wali' | 'admin' (sudah dinormalisasi).
  final String role;

  /// `profile['id']` — hanya terisi untuk role siswa.
  final int? siswaId;

  final bool canCreate;
  final bool canPengembalian;
  final bool canLihatRiwayat;

  const PerpustakaanLoadRequested({
    required this.role,
    this.siswaId,
    this.canCreate = false,
    this.canPengembalian = false,
    this.canLihatRiwayat = false,
  });

  @override
  List<Object?> get props => [
    role,
    siswaId,
    canCreate,
    canPengembalian,
    canLihatRiwayat,
  ];
}

class PerpustakaanRefreshRequested extends PerpustakaanEvent {
  final PerpustakaanScope scope;
  const PerpustakaanRefreshRequested([this.scope = PerpustakaanScope.semua]);

  @override
  List<Object?> get props => [scope];
}

class PerpustakaanSearchChanged extends PerpustakaanEvent {
  final String query;
  const PerpustakaanSearchChanged(this.query);

  @override
  List<Object?> get props => [query];
}

class PerpustakaanHanyaTersediaChanged extends PerpustakaanEvent {
  final bool value;
  const PerpustakaanHanyaTersediaChanged(this.value);

  @override
  List<Object?> get props => [value];
}

/// Buat peminjaman baru (butuh permission `peminjaman.create`).
class PerpustakaanPinjamRequested extends PerpustakaanEvent {
  final int bukuId;
  final int siswaId;

  /// Format `YYYY-MM-DD`. Selalu dikirim supaya aturan validasi backend
  /// `after:tanggal_pinjam` punya pembanding yang jelas.
  final String tanggalPinjam;
  final String tanggalJatuhTempo;

  const PerpustakaanPinjamRequested({
    required this.bukuId,
    required this.siswaId,
    required this.tanggalPinjam,
    required this.tanggalJatuhTempo,
  });

  @override
  List<Object?> get props => [
    bukuId,
    siswaId,
    tanggalPinjam,
    tanggalJatuhTempo,
  ];
}

/// Proses pengembalian (butuh permission `peminjaman.pengembalian`).
class PerpustakaanPengembalianRequested extends PerpustakaanEvent {
  final int peminjamanId;
  const PerpustakaanPengembalianRequested(this.peminjamanId);

  @override
  List<Object?> get props => [peminjamanId];
}
