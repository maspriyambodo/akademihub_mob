import 'package:equatable/equatable.dart';

/// Dokumen milik satu pendaftar PPDB.
///
/// Sumber: tabel `ppdb_dokumen` via `PpdbDokumenResource`
/// (endpoint `/ppdb/dokumen/pendaftaran/{id}`), atau versi ringkas yang
/// menempel pada `PpdbPendaftaranResource.dokumens` (tanpa `catatan_admin`).
class PpdbDokumenEntity extends Equatable {
  final int id;
  final int? pendaftarId;

  /// Mis. `kartukeluarga`, `akte`, `rapor`, `ijazah`.
  final String jenisDokumen;
  final String fileName;
  final String? mimeType;
  final int? fileSize;

  /// Boolean di backend: `true` = terverifikasi, `false` = belum / ditolak.
  final bool verifikasiStatus;

  /// Catatan admin — untuk dokumen ditolak berisi alasan penolakan.
  final String? catatanAdmin;

  const PpdbDokumenEntity({
    required this.id,
    this.pendaftarId,
    this.jenisDokumen = '',
    this.fileName = '',
    this.mimeType,
    this.fileSize,
    this.verifikasiStatus = false,
    this.catatanAdmin,
  });

  @override
  List<Object?> get props => [id];
}
