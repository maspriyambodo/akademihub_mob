import '../../domain/entities/ppdb_hasil_seleksi_entity.dart';
import 'ppdb_parse_utils.dart';

/// Model hasil seleksi (`PpdbHasilSeleksiResource`).
class PpdbHasilSeleksiModel {
  final int id;
  final int? pendaftarId;
  final int? gelombangId;
  final double? totalSkor;
  final int? peringkat;
  final int? peringkatJurusan;
  final String statusSeleksi;
  final String? statusSeleksiLabel;
  final bool isFinalized;
  final String? catatanSeleksi;
  final String? namaJurusan;

  const PpdbHasilSeleksiModel({
    required this.id,
    this.pendaftarId,
    this.gelombangId,
    this.totalSkor,
    this.peringkat,
    this.peringkatJurusan,
    this.statusSeleksi = 'menunggu',
    this.statusSeleksiLabel,
    this.isFinalized = false,
    this.catatanSeleksi,
    this.namaJurusan,
  });

  factory PpdbHasilSeleksiModel.fromJson(Map<String, dynamic> json) {
    final kuotaRaw = json['kuota_jurusan'];
    return PpdbHasilSeleksiModel(
      id: parseIntOrNull(json['id']) ?? 0,
      pendaftarId: parseIntOrNull(json['ppdb_pendaftar_id']),
      gelombangId: parseIntOrNull(json['ppdb_gelombang_id']),
      totalSkor: parseDoubleOrNull(json['total_skor']),
      peringkat: parseIntOrNull(json['peringkat']),
      peringkatJurusan: parseIntOrNull(json['peringkat_jurusan']),
      statusSeleksi: json['status_seleksi'] as String? ?? 'menunggu',
      statusSeleksiLabel: json['status_seleksi_label'] as String?,
      isFinalized: parseBool(json['is_finalized']),
      catatanSeleksi: json['catatan_seleksi'] as String?,
      namaJurusan: kuotaRaw is Map<String, dynamic>
          ? kuotaRaw['nama_jurusan'] as String?
          : null,
    );
  }

  PpdbHasilSeleksiEntity toEntity() => PpdbHasilSeleksiEntity(
    id: id,
    pendaftarId: pendaftarId,
    gelombangId: gelombangId,
    totalSkor: totalSkor,
    peringkat: peringkat,
    peringkatJurusan: peringkatJurusan,
    statusSeleksi: statusSeleksi,
    statusSeleksiLabel: statusSeleksiLabel,
    isFinalized: isFinalized,
    catatanSeleksi: catatanSeleksi,
    namaJurusan: namaJurusan,
  );
}
