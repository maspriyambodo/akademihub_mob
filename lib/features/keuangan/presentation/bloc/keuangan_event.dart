part of 'keuangan_bloc.dart';

abstract class KeuanganEvent extends Equatable {
  const KeuanganEvent();
  @override
  List<Object?> get props => [];
}

/// Muat awal. [kelasId] dipakai untuk mencari tarif SPP siswa
/// (`profile['kelas']['id']`), boleh null.
class KeuanganLoadRequested extends KeuanganEvent {
  final String role;
  final int? profileId;
  final int? kelasId;

  const KeuanganLoadRequested({
    required this.role,
    this.profileId,
    this.kelasId,
  });

  @override
  List<Object?> get props => [role, profileId, kelasId];
}

class KeuanganRefreshRequested extends KeuanganEvent {
  const KeuanganRefreshRequested();
}

/// Pencarian nama/NIS siswa (mode admin/petugas/guru).
class KeuanganSearchChanged extends KeuanganEvent {
  final String query;
  const KeuanganSearchChanged(this.query);

  @override
  List<Object?> get props => [query];
}

/// Ganti tahun untuk rekap tunggakan, status, dan laporan periode.
class KeuanganTahunChanged extends KeuanganEvent {
  final int tahun;
  const KeuanganTahunChanged(this.tahun);

  @override
  List<Object?> get props => [tahun];
}

/// Inisiasi pembayaran online Midtrans untuk satu bulan tunggakan.
class KeuanganBayarOnlineRequested extends KeuanganEvent {
  final int bulan;
  final int tahun;

  const KeuanganBayarOnlineRequested({
    required this.bulan,
    required this.tahun,
  });

  @override
  List<Object?> get props => [bulan, tahun];
}

/// Catat pelunasan beberapa bulan sekaligus (aksi admin/petugas).
class KeuanganBayarMultipleRequested extends KeuanganEvent {
  final List<int> bulan;
  final int tahun;

  const KeuanganBayarMultipleRequested({
    required this.bulan,
    required this.tahun,
  });

  @override
  List<Object?> get props => [bulan, tahun];
}
