import '../../domain/entities/nilai_entity.dart';

class NilaiModel {
  final int id;
  final int? ujianId;
  final int? siswaId;
  final String? siswaNama;
  final String? siswaNis;
  final String? ujianNama;
  final String? jenisPenilaian;
  final String? jenisKode;
  final String? semester;
  final String? semesterKode;
  final String? tahunAjaran;
  final String? tanggalUjian;
  final int? mapelId;
  final String? mapelNama;
  final String? kelasNama;
  final double? nilai;
  final String? keterangan;

  const NilaiModel({
    required this.id,
    this.ujianId,
    this.siswaId,
    this.siswaNama,
    this.siswaNis,
    this.ujianNama,
    this.jenisPenilaian,
    this.jenisKode,
    this.semester,
    this.semesterKode,
    this.tahunAjaran,
    this.tanggalUjian,
    this.mapelId,
    this.mapelNama,
    this.kelasNama,
    this.nilai,
    this.keterangan,
  });

  /// Backend memakai cast `decimal:2` untuk kolom `nilai`, sehingga JSON bisa
  /// berisi string ("85.00") atau angka. Rata-rata dikirim sebagai float.
  static double? parseNilai(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) {
      final normalized = value.trim().replaceAll(',', '.');
      if (normalized.isEmpty) return null;
      return double.tryParse(normalized);
    }
    return null;
  }

  static String? _asString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    return value.toString();
  }

  factory NilaiModel.fromJson(Map<String, dynamic> json) {
    // `siswa` dan `ujian` memakai whenLoaded() di backend, jadi key-nya bisa
    // hilang sama sekali tergantung endpoint yang dipanggil.
    final siswa = json['siswa'] as Map<String, dynamic>?;
    final ujian = json['ujian'] as Map<String, dynamic>?;
    final mapel = ujian?['mapel'] as Map<String, dynamic>?;
    final kelas = ujian?['kelas'] as Map<String, dynamic>?;

    return NilaiModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      ujianId:
          (json['trx_ujian_id'] as num?)?.toInt() ??
          (ujian?['id'] as num?)?.toInt(),
      siswaId:
          (json['mst_siswa_id'] as num?)?.toInt() ??
          (siswa?['id'] as num?)?.toInt(),
      siswaNama: siswa?['nama'] as String?,
      siswaNis: _asString(siswa?['nis']),
      ujianNama: ujian?['nama'] as String?,
      jenisPenilaian: ujian?['jenis'] as String?,
      jenisKode: _asString(ujian?['jenis_kode']),
      semester: ujian?['semester'] as String?,
      semesterKode: _asString(ujian?['semester_kode']),
      tahunAjaran: _asString(ujian?['tahun_ajaran']),
      tanggalUjian: ujian?['tanggal'] as String?,
      mapelId: (mapel?['id'] as num?)?.toInt(),
      mapelNama: mapel?['nama'] as String?,
      kelasNama: kelas?['nama_kelas'] as String?,
      nilai: parseNilai(json['nilai']),
      keterangan: json['keterangan'] as String?,
    );
  }

  NilaiEntity toEntity() => NilaiEntity(
    id: id,
    ujianId: ujianId,
    siswaId: siswaId,
    siswaNama: siswaNama,
    siswaNis: siswaNis,
    ujianNama: ujianNama,
    jenisPenilaian: jenisPenilaian,
    jenisKode: jenisKode,
    semester: semester,
    semesterKode: semesterKode,
    tahunAjaran: tahunAjaran,
    tanggalUjian: tanggalUjian,
    mapelId: mapelId,
    mapelNama: mapelNama,
    kelasNama: kelasNama,
    nilai: nilai,
    keterangan: keterangan,
  );
}
