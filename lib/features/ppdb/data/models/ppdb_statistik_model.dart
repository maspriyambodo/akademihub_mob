import '../../domain/entities/ppdb_statistik_entity.dart';
import 'ppdb_parse_utils.dart';

/// Model statistik pendaftaran
/// (`GET /ppdb/pendaftaran/sekolah/{sekolahId}/statistics` →
/// `PpdbPendaftaranService::getStatistics`).
class PpdbStatistikModel {
  final int total;
  final int draft;
  final int terverifikasi;
  final int seleksi;
  final int diterima;
  final int cadangan;
  final int ditolak;

  const PpdbStatistikModel({
    this.total = 0,
    this.draft = 0,
    this.terverifikasi = 0,
    this.seleksi = 0,
    this.diterima = 0,
    this.cadangan = 0,
    this.ditolak = 0,
  });

  factory PpdbStatistikModel.fromJson(Map<String, dynamic> json) {
    return PpdbStatistikModel(
      total: parseIntOrNull(json['total']) ?? 0,
      draft: parseIntOrNull(json['draft']) ?? 0,
      terverifikasi: parseIntOrNull(json['terverifikasi']) ?? 0,
      seleksi: parseIntOrNull(json['seleksi']) ?? 0,
      diterima: parseIntOrNull(json['diterima']) ?? 0,
      cadangan: parseIntOrNull(json['cadangan']) ?? 0,
      ditolak: parseIntOrNull(json['ditolak']) ?? 0,
    );
  }

  PpdbStatistikEntity toEntity() => PpdbStatistikEntity(
    total: total,
    draft: draft,
    terverifikasi: terverifikasi,
    seleksi: seleksi,
    diterima: diterima,
    cadangan: cadangan,
    ditolak: ditolak,
    dariServer: true,
  );
}
