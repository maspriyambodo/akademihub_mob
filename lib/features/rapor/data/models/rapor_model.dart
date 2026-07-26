import '../../domain/entities/rapor_entity.dart';
import 'rapor_mapel_model.dart';

/// Mapping dari `RaporResource` (Laravel).
///
/// Bentuk JSON:
/// ```json
/// {
///   "id": 1,
///   "mst_siswa_id": 10,
///   "tahun_ajaran_id": 3,
///   "semester_kode": "5",
///   "siswa": { "id": 10, "nama": "...", "nis": "..." },
///   "kelas": "XII IPA 1",
///   "semester": "Ganjil",
///   "tahun_ajaran": "2024/2025",
///   "catatan_wali": "...",
///   "kehadiran": { "sakit": 1, "izin": 0, "tanpa_keterangan": 2 },
///   "total_nilai": "850.00",
///   "rata_rata": "85.00",
///   "ranking": { "peringkat": 3 },
///   "detail": [ { "id": 1, "mapel": {...}, ... } ],
///   "created_at": "...", "updated_at": "..."
/// }
/// ```
/// `siswa`, `ranking`, dan `detail` memakai `whenLoaded` → key-nya bisa HILANG
/// sama sekali (bukan null) bila relasi tidak di-eager-load.
class RaporModel {
  final int id;
  final int? siswaId;
  final String? siswaNama;
  final String? siswaNis;
  final String? kelas;
  final String? semester;
  final String? semesterKode;
  final int? tahunAjaranId;
  final String? tahunAjaran;
  final String? catatanWali;
  final double? totalNilai;
  final double? rataRata;
  final int? sakit;
  final int? izin;
  final int? tanpaKeterangan;
  final int? peringkat;
  final List<RaporMapelModel> detail;

  const RaporModel({
    required this.id,
    this.siswaId,
    this.siswaNama,
    this.siswaNis,
    this.kelas,
    this.semester,
    this.semesterKode,
    this.tahunAjaranId,
    this.tahunAjaran,
    this.catatanWali,
    this.totalNilai,
    this.rataRata,
    this.sakit,
    this.izin,
    this.tanpaKeterangan,
    this.peringkat,
    this.detail = const [],
  });

  factory RaporModel.fromJson(Map<String, dynamic> json) {
    final siswa = json['siswa'] as Map<String, dynamic>?;
    final kehadiran = json['kehadiran'] as Map<String, dynamic>?;
    final ranking = json['ranking'] as Map<String, dynamic>?;

    return RaporModel(
      id: raporToInt(json['id']) ?? 0,
      siswaId: raporToInt(json['mst_siswa_id']) ?? raporToInt(siswa?['id']),
      siswaNama: raporToText(siswa?['nama']),
      siswaNis: raporToText(siswa?['nis']),
      // Backend mengirim `kelas` sebagai string nama_kelas.
      kelas: raporToText(json['kelas']),
      semester: raporToText(json['semester']),
      semesterKode: raporToText(json['semester_kode']),
      tahunAjaranId: raporToInt(json['tahun_ajaran_id']),
      tahunAjaran: raporToText(json['tahun_ajaran']),
      catatanWali: raporToText(json['catatan_wali']),
      totalNilai: raporToDouble(json['total_nilai']),
      rataRata: raporToDouble(json['rata_rata']),
      sakit: raporToInt(kehadiran?['sakit']),
      izin: raporToInt(kehadiran?['izin']),
      tanpaKeterangan: raporToInt(kehadiran?['tanpa_keterangan']),
      peringkat: raporToInt(ranking?['peringkat']),
      detail: raporMapelListFromJson(json['detail']),
    );
  }

  RaporEntity toEntity() => RaporEntity(
    id: id,
    siswaId: siswaId,
    siswaNama: siswaNama,
    siswaNis: siswaNis,
    kelas: kelas,
    semester: semester,
    semesterKode: semesterKode,
    tahunAjaranId: tahunAjaranId,
    tahunAjaran: tahunAjaran,
    catatanWali: catatanWali,
    totalNilai: totalNilai,
    rataRata: rataRata,
    sakit: sakit,
    izin: izin,
    tanpaKeterangan: tanpaKeterangan,
    peringkat: peringkat,
    detail: detail.map((d) => d.toEntity()).toList(),
  );
}
