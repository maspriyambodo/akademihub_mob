import '../../domain/entities/ujian_entity.dart';

/// Model `UjianResource`. Semua parsing null-safe; kolom desimal/angka
/// bisa datang sebagai num maupun String dari PostgreSQL.
class UjianModel {
  final int id;
  final String nama;
  final String? jenisLabel;
  final String? jenisKode;
  final int? mapelId;
  final String? mapelNama;
  final String? mapelKode;
  final int? kelasId;
  final String? kelasNama;
  final String? tanggal;
  final String? semesterNama;
  final String? semesterKode;
  final String? tahunAjaran;
  final String? keterangan;

  const UjianModel({
    required this.id,
    required this.nama,
    this.jenisLabel,
    this.jenisKode,
    this.mapelId,
    this.mapelNama,
    this.mapelKode,
    this.kelasId,
    this.kelasNama,
    this.tanggal,
    this.semesterNama,
    this.semesterKode,
    this.tahunAjaran,
    this.keterangan,
  });

  factory UjianModel.fromJson(Map<String, dynamic> json) {
    // Relasi `mapel`/`kelas` memakai whenLoaded → bisa tidak ada / bukan Map.
    final mapel = json['mapel'] is Map ? json['mapel'] as Map : null;
    final kelas = json['kelas'] is Map ? json['kelas'] as Map : null;
    return UjianModel(
      id: (json['id'] as num).toInt(),
      nama: json['nama'] as String? ?? '',
      jenisLabel: json['jenis']?.toString(),
      jenisKode: json['jenis_kode']?.toString(),
      mapelId: (mapel?['id'] as num?)?.toInt(),
      mapelNama: mapel?['nama'] as String?,
      mapelKode: mapel?['kode'] as String?,
      kelasId:
          (kelas?['id'] as num?)?.toInt() ??
          (json['mst_kelas_id'] as num?)?.toInt(),
      kelasNama: kelas?['nama_kelas'] as String?,
      tanggal: json['tanggal'] as String?,
      semesterNama: json['semester']?.toString(),
      semesterKode: json['semester_kode']?.toString(),
      tahunAjaran: json['tahun_ajaran'] as String?,
      keterangan: json['keterangan'] as String?,
    );
  }

  UjianEntity toEntity() => UjianEntity(
    id: id,
    nama: nama,
    jenisLabel: jenisLabel,
    jenisKode: jenisKode,
    mapelId: mapelId,
    mapelNama: mapelNama,
    mapelKode: mapelKode,
    kelasId: kelasId,
    kelasNama: kelasNama,
    tanggal: tanggal,
    semesterNama: semesterNama,
    semesterKode: semesterKode,
    tahunAjaran: tahunAjaran,
    keterangan: keterangan,
  );
}
