import '../../domain/entities/tarif_spp_entity.dart';
import 'keuangan_json.dart';

/// Mapping dari `TarifSppResource` (Laravel).
///
/// ```json
/// {
///   "id": 1,
///   "kelas": { "id": 5, "nama_kelas": "X IPA 1", "tingkat": "10" },
///   "tahun_ajaran": "2026/2027",
///   "nominal": "350000.00",
///   "keterangan": "SPP reguler",
///   "created_at": "...", "updated_at": "..."
/// }
/// ```
/// `kelas` memakai `whenLoaded` → bisa hilang. `tahun_ajaran` sudah berupa
/// STRING nama tahun ajaran (`$this->tahunAjaran?->nama`), bukan objek.
class TarifSppModel {
  final int id;
  final int? kelasId;
  final String? kelasNama;
  final String? tingkat;
  final String? tahunAjaran;
  final double? nominal;
  final String? keterangan;

  const TarifSppModel({
    required this.id,
    this.kelasId,
    this.kelasNama,
    this.tingkat,
    this.tahunAjaran,
    this.nominal,
    this.keterangan,
  });

  factory TarifSppModel.fromJson(Map<String, dynamic> json) {
    final kelas = keuToMap(json['kelas']);
    return TarifSppModel(
      id: keuToIntOr(json['id']),
      kelasId: keuToInt(kelas?['id']),
      kelasNama: keuToText(kelas?['nama_kelas']),
      tingkat: keuToText(kelas?['tingkat']),
      tahunAjaran: keuToText(json['tahun_ajaran']),
      nominal: keuToDouble(json['nominal']),
      keterangan: keuToText(json['keterangan']),
    );
  }

  TarifSppEntity toEntity() => TarifSppEntity(
    id: id,
    kelasId: kelasId,
    kelasNama: kelasNama,
    tingkat: tingkat,
    tahunAjaran: tahunAjaran,
    nominal: nominal,
    keterangan: keterangan,
  );
}
