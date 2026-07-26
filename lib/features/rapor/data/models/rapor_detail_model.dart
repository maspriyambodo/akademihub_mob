import '../../domain/entities/rapor_detail_entity.dart';
import 'rapor_mapel_model.dart';

/// Mapping dari `RaporService::getRaporDetail()`
/// (endpoint `GET /akademik/rapor/{id}/detail`).
///
/// Bentuk JSON:
/// ```json
/// {
///   "id": 1,
///   "mst_siswa_id": 10,
///   "siswa": { "id": 10, "nis": "...", "nama": "..." },
///   "semester": "Ganjil",
///   "tahun_ajaran": "2024/2025",
///   "catatan_wali": "Narasi wali kelas ...",
///   "kehadiran": { "sakit": 1, "izin": 0, "tanpa_keterangan": 2 },
///   "detail": [
///     {
///       "mapel": { "id": 4, "kode": "MTK", "nama": "Matematika" },
///       "nilai_pengetahuan": "88.00",
///       "nilai_keterampilan": null,
///       "nilai_akhir": "88.00",
///       "predikat": "B",
///       "deskripsi": null
///     }
///   ]
/// }
/// ```
/// Bila rapor tidak ditemukan / tidak boleh diakses, backend mengembalikan
/// `data: []` (array kosong, bukan objek) — ditangani di datasource.
class RaporDetailModel {
  final int id;
  final int? siswaId;
  final String? siswaNama;
  final String? siswaNis;
  final String? semester;
  final String? tahunAjaran;
  final String? catatanWali;
  final int? sakit;
  final int? izin;
  final int? tanpaKeterangan;
  final List<RaporMapelModel> mapel;

  const RaporDetailModel({
    required this.id,
    this.siswaId,
    this.siswaNama,
    this.siswaNis,
    this.semester,
    this.tahunAjaran,
    this.catatanWali,
    this.sakit,
    this.izin,
    this.tanpaKeterangan,
    this.mapel = const [],
  });

  factory RaporDetailModel.fromJson(Map<String, dynamic> json) {
    final siswa = json['siswa'] as Map<String, dynamic>?;
    final kehadiran = json['kehadiran'] as Map<String, dynamic>?;

    return RaporDetailModel(
      id: raporToInt(json['id']) ?? 0,
      siswaId: raporToInt(json['mst_siswa_id']) ?? raporToInt(siswa?['id']),
      siswaNama: raporToText(siswa?['nama']),
      siswaNis: raporToText(siswa?['nis']),
      semester: raporToText(json['semester']),
      tahunAjaran: raporToText(json['tahun_ajaran']),
      catatanWali: raporToText(json['catatan_wali']),
      sakit: raporToInt(kehadiran?['sakit']),
      izin: raporToInt(kehadiran?['izin']),
      tanpaKeterangan: raporToInt(kehadiran?['tanpa_keterangan']),
      mapel: raporMapelListFromJson(json['detail']),
    );
  }

  RaporDetailEntity toEntity() => RaporDetailEntity(
    id: id,
    siswaId: siswaId,
    siswaNama: siswaNama,
    siswaNis: siswaNis,
    semester: semester,
    tahunAjaran: tahunAjaran,
    catatanWali: catatanWali,
    sakit: sakit,
    izin: izin,
    tanpaKeterangan: tanpaKeterangan,
    mapel: mapel.map((m) => m.toEntity()).toList(),
  );
}
