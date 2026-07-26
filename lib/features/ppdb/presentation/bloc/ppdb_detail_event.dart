part of 'ppdb_detail_bloc.dart';

abstract class PpdbDetailEvent extends Equatable {
  const PpdbDetailEvent();

  @override
  List<Object?> get props => [];
}

class PpdbDetailLoadRequested extends PpdbDetailEvent {
  final int pendaftarId;

  /// Izin `ppdb.dokumen.by-pendaftaran` — dokumen lengkap + catatan admin.
  final bool bolehLihatDokumen;

  /// Izin `ppdb.seleksi.view` — hasil seleksi otomatis.
  final bool bolehLihatSeleksi;

  const PpdbDetailLoadRequested({
    required this.pendaftarId,
    required this.bolehLihatDokumen,
    required this.bolehLihatSeleksi,
  });

  @override
  List<Object?> get props => [pendaftarId, bolehLihatDokumen, bolehLihatSeleksi];
}

class PpdbDetailRefreshRequested extends PpdbDetailEvent {
  const PpdbDetailRefreshRequested();
}

/// POST `/ppdb/dokumen/{id}/verify` — `catatan` opsional.
class PpdbDokumenVerifikasiDiminta extends PpdbDetailEvent {
  final int dokumenId;
  final String? catatan;

  const PpdbDokumenVerifikasiDiminta(this.dokumenId, {this.catatan});

  @override
  List<Object?> get props => [dokumenId, catatan];
}

/// POST `/ppdb/dokumen/{id}/reject` — `catatan` wajib diisi.
class PpdbDokumenTolakDiminta extends PpdbDetailEvent {
  final int dokumenId;
  final String catatan;

  const PpdbDokumenTolakDiminta(this.dokumenId, {required this.catatan});

  @override
  List<Object?> get props => [dokumenId, catatan];
}

/// POST `/ppdb/pendaftaran/{id}/{aksi}` — [aksi]: `verify` | `accept` |
/// `reject`.
class PpdbPendaftarAksiDiminta extends PpdbDetailEvent {
  final String aksi;
  const PpdbPendaftarAksiDiminta(this.aksi);

  @override
  List<Object?> get props => [aksi];
}
