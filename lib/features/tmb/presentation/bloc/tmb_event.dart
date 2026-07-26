part of 'tmb_bloc.dart';

abstract class TmbEvent extends Equatable {
  const TmbEvent();

  @override
  List<Object?> get props => [];
}

class TmbLoadRequested extends TmbEvent {
  final String role;
  final int? siswaId;
  final int? kelasId;

  /// `tes-minat-bakat.view` — tanpa ini seluruh halaman jadi akses ditolak.
  final bool hasViewTes;

  /// `tes-minat-bakat-peserta.create` — siswa default TIDAK memilikinya
  /// (pendaftaran peserta dilakukan admin), tombol daftar hanya muncul bila
  /// izin ada.
  final bool canDaftar;

  final bool canMulai;
  final bool canSelesaikan;
  final bool canKirimJawaban;
  final bool canViewPeserta;

  /// `tes-minat-bakat-pertanyaan.view`. Bila false, pertanyaan diambil via
  /// `GET /tes-minat-bakat/{id}` (jalur siswa).
  final bool canViewPertanyaanEndpoint;

  /// `tes-minat-bakat-hasil.view` — dipakai hanya untuk role staf, karena
  /// endpoint hasil by-peserta error untuk role siswa/wali di backend.
  final bool canViewHasilEndpoint;

  const TmbLoadRequested({
    required this.role,
    this.siswaId,
    this.kelasId,
    required this.hasViewTes,
    this.canDaftar = false,
    this.canMulai = false,
    this.canSelesaikan = false,
    this.canKirimJawaban = false,
    this.canViewPeserta = false,
    this.canViewPertanyaanEndpoint = false,
    this.canViewHasilEndpoint = false,
  });

  @override
  List<Object?> get props => [role, siswaId, kelasId, hasViewTes];
}

class TmbRefreshRequested extends TmbEvent {
  const TmbRefreshRequested();
}

class TmbDaftarRequested extends TmbEvent {
  final int tesId;
  const TmbDaftarRequested(this.tesId);

  @override
  List<Object?> get props => [tesId];
}
