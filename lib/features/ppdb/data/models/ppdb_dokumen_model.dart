import '../../domain/entities/ppdb_dokumen_entity.dart';
import 'ppdb_parse_utils.dart';

/// Model dokumen PPDB.
///
/// Field diverifikasi terhadap `PpdbDokumenResource`. Versi ringkas yang
/// menempel pada `PpdbPendaftaranResource.dokumens` hanya memuat
/// `id`, `jenis_dokumen`, `file_name`, `verifikasi_status` — field lain null.
class PpdbDokumenModel {
  final int id;
  final int? pendaftarId;
  final String jenisDokumen;
  final String fileName;
  final String? mimeType;
  final int? fileSize;
  final bool verifikasiStatus;
  final String? catatanAdmin;

  const PpdbDokumenModel({
    required this.id,
    this.pendaftarId,
    this.jenisDokumen = '',
    this.fileName = '',
    this.mimeType,
    this.fileSize,
    this.verifikasiStatus = false,
    this.catatanAdmin,
  });

  factory PpdbDokumenModel.fromJson(Map<String, dynamic> json) {
    return PpdbDokumenModel(
      id: parseIntOrNull(json['id']) ?? 0,
      pendaftarId: parseIntOrNull(json['ppdb_pendaftar_id']),
      jenisDokumen: json['jenis_dokumen'] as String? ?? '',
      fileName: json['file_name'] as String? ?? '',
      mimeType: json['mime_type'] as String?,
      fileSize: parseIntOrNull(json['file_size']),
      verifikasiStatus: parseBool(json['verifikasi_status']),
      catatanAdmin: json['catatan_admin'] as String?,
    );
  }

  PpdbDokumenEntity toEntity() => PpdbDokumenEntity(
    id: id,
    pendaftarId: pendaftarId,
    jenisDokumen: jenisDokumen,
    fileName: fileName,
    mimeType: mimeType,
    fileSize: fileSize,
    verifikasiStatus: verifikasiStatus,
    catatanAdmin: catatanAdmin,
  );
}
