import '../../domain/entities/ppdb_nilai_rapor_entity.dart';
import 'ppdb_parse_utils.dart';

/// Model nilai rapor pendaftar (model Eloquent mentah, bukan Resource):
/// `{ id, ppdb_pendaftar_id, kode_mapel, nilai }` — `nilai` decimal:2
/// terserialisasi sebagai String.
class PpdbNilaiRaporModel {
  final int id;
  final String kodeMapel;
  final double? nilai;

  const PpdbNilaiRaporModel({
    required this.id,
    this.kodeMapel = '',
    this.nilai,
  });

  factory PpdbNilaiRaporModel.fromJson(Map<String, dynamic> json) {
    return PpdbNilaiRaporModel(
      id: parseIntOrNull(json['id']) ?? 0,
      kodeMapel: json['kode_mapel'] as String? ?? '',
      nilai: parseDoubleOrNull(json['nilai']),
    );
  }

  PpdbNilaiRaporEntity toEntity() =>
      PpdbNilaiRaporEntity(id: id, kodeMapel: kodeMapel, nilai: nilai);
}

/// Bagian `statistik` pada response `/ppdb/nilai-rapor/pendaftaran/{id}`
/// (`PpdbPendaftarNilaiRaporService::getStatistik`).
class PpdbNilaiStatistikModel {
  final int jumlahMapel;
  final double? rataRata;
  final double? nilaiTertinggi;
  final double? nilaiTerendah;

  const PpdbNilaiStatistikModel({
    this.jumlahMapel = 0,
    this.rataRata,
    this.nilaiTertinggi,
    this.nilaiTerendah,
  });

  factory PpdbNilaiStatistikModel.fromJson(Map<String, dynamic> json) {
    return PpdbNilaiStatistikModel(
      jumlahMapel: parseIntOrNull(json['jumlah_mapel']) ?? 0,
      rataRata: parseDoubleOrNull(json['rata_rata']),
      nilaiTertinggi: parseDoubleOrNull(json['nilai_tertinggi']),
      nilaiTerendah: parseDoubleOrNull(json['nilai_terendah']),
    );
  }

  PpdbNilaiStatistikEntity toEntity() => PpdbNilaiStatistikEntity(
    jumlahMapel: jumlahMapel,
    rataRata: rataRata,
    nilaiTertinggi: nilaiTertinggi,
    nilaiTerendah: nilaiTerendah,
  );
}
