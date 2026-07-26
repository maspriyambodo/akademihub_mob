import '../../domain/entities/tugas_siswa_entity.dart';

/// Model pengumpulan tugas — parsing manual dari `TugasSiswaResource` backend.
class TugasSiswaModel {
  final int id;
  final int? tugasId;
  final int? siswaId;
  final String? jawaban;
  final String? fileJawaban;
  final String? waktuKumpul;
  final double? nilai;
  final String? catatanGuru;
  final int status;
  final String? statusLabel;
  final String? siswaNama;
  final String? siswaNis;
  final String? tugasJudul;
  final String? tugasDeskripsi;
  final String? tugasTenggatWaktu;
  final int? tugasKelasId;
  final String? tugasKelasNama;
  final String? tugasMapelNama;
  final String? tugasGuruNama;

  const TugasSiswaModel({
    required this.id,
    this.tugasId,
    this.siswaId,
    this.jawaban,
    this.fileJawaban,
    this.waktuKumpul,
    this.nilai,
    this.catatanGuru,
    this.status = 0,
    this.statusLabel,
    this.siswaNama,
    this.siswaNis,
    this.tugasJudul,
    this.tugasDeskripsi,
    this.tugasTenggatWaktu,
    this.tugasKelasId,
    this.tugasKelasNama,
    this.tugasMapelNama,
    this.tugasGuruNama,
  });

  factory TugasSiswaModel.fromJson(Map<String, dynamic> json) {
    final siswa = json['siswa'] as Map<String, dynamic>?;
    final tugas = json['tugas'] as Map<String, dynamic>?;
    final tugasGuruMapel = tugas?['guru_mapel'] as Map<String, dynamic>?;
    final tugasGuru = tugasGuruMapel?['guru'] as Map<String, dynamic>?;
    final tugasMapel = tugasGuruMapel?['mapel'] as Map<String, dynamic>?;
    final tugasKelas = tugas?['kelas'] as Map<String, dynamic>?;

    return TugasSiswaModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      tugasId:
          (json['tugas_id'] as num?)?.toInt() ??
          (tugas?['id'] as num?)?.toInt(),
      siswaId:
          (json['siswa_id'] as num?)?.toInt() ??
          (siswa?['id'] as num?)?.toInt(),
      jawaban: json['jawaban'] as String?,
      fileJawaban: json['file_jawaban'] as String?,
      waktuKumpul:
          json['waktu_kumpul'] as String? ?? json['waktu_kumpl'] as String?,
      nilai: (json['nilai'] as num?)?.toDouble(),
      catatanGuru: json['catatan_guru'] as String?,
      status:
          (json['status'] as num?)?.toInt() ??
          (json['status_kumpul'] as num?)?.toInt() ??
          0,
      statusLabel:
          json['status_label'] as String? ??
          json['status_kumpul_label'] as String?,
      siswaNama: siswa?['nama'] as String?,
      siswaNis: siswa?['nis'] as String?,
      tugasJudul: tugas?['judul'] as String?,
      tugasDeskripsi: tugas?['deskripsi'] as String?,
      tugasTenggatWaktu: tugas?['tenggat_waktu'] as String?,
      tugasKelasId: (tugasKelas?['id'] as num?)?.toInt(),
      tugasKelasNama: tugasKelas?['nama'] as String?,
      tugasMapelNama:
          tugasMapel?['nama'] as String? ?? tugasMapel?['kode'] as String?,
      tugasGuruNama: tugasGuru?['nama'] as String?,
    );
  }

  TugasSiswaEntity toEntity() => TugasSiswaEntity(
    id: id,
    tugasId: tugasId,
    siswaId: siswaId,
    jawaban: jawaban,
    fileJawaban: fileJawaban,
    waktuKumpul: waktuKumpul,
    nilai: nilai,
    catatanGuru: catatanGuru,
    status: status,
    statusLabel: statusLabel,
    siswaNama: siswaNama,
    siswaNis: siswaNis,
    tugasJudul: tugasJudul,
    tugasDeskripsi: tugasDeskripsi,
    tugasTenggatWaktu: tugasTenggatWaktu,
    tugasKelasId: tugasKelasId,
    tugasKelasNama: tugasKelasNama,
    tugasMapelNama: tugasMapelNama,
    tugasGuruNama: tugasGuruNama,
  );
}
