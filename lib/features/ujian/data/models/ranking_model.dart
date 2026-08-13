import '../../domain/entities/ranking_entity.dart';
import 'ujian_nilai_model.dart' show parseUjianNilai;

/// Model `RankingResource`.
class RankingModel {
  final int id;
  final int? raporId;
  final int? kelasId;
  final int? siswaId;
  final String? siswaNama;
  final String? nis;
  final String? kelasNama;
  final int? semesterId;
  final String? semesterNama;
  final String? tahunAjaran;
  final double? rataRata;
  final int? peringkat;

  const RankingModel({
    required this.id,
    this.raporId,
    this.kelasId,
    this.siswaId,
    this.siswaNama,
    this.nis,
    this.kelasNama,
    this.semesterId,
    this.semesterNama,
    this.tahunAjaran,
    this.rataRata,
    this.peringkat,
  });

  factory RankingModel.fromJson(Map<String, dynamic> json) {
    final siswa = json['siswa'] is Map ? json['siswa'] as Map : null;
    final kelas = json['kelas'] is Map ? json['kelas'] as Map : null;

    // `semester` di RankingResource adalah id mst_semester mentah
    // (int, kadang String).
    final semesterRaw = json['semester'];
    final int? semesterId;
    if (semesterRaw is num) {
      semesterId = semesterRaw.toInt();
    } else if (semesterRaw is String) {
      semesterId = int.tryParse(semesterRaw);
    } else {
      semesterId = null;
    }

    return RankingModel(
      id: (json['id'] as num).toInt(),
      raporId: (json['trx_rapor_id'] as num?)?.toInt(),
      kelasId: (json['mst_kelas_id'] as num?)?.toInt(),
      siswaId:
          (json['mst_siswa_id'] as num?)?.toInt() ??
          (siswa?['id'] as num?)?.toInt(),
      siswaNama: siswa?['nama'] as String?,
      nis: json['nis']?.toString() ?? siswa?['nis']?.toString(),
      kelasNama: kelas?['nama_kelas'] as String?,
      semesterId: semesterId,
      semesterNama: json['semester_nama'] as String?,
      tahunAjaran: json['tahun_ajaran'] as String?,
      rataRata: parseUjianNilai(json['rata_rata_nilai']),
      peringkat: (json['peringkat'] as num?)?.toInt(),
    );
  }

  RankingEntity toEntity() => RankingEntity(
    id: id,
    raporId: raporId,
    kelasId: kelasId,
    siswaId: siswaId,
    siswaNama: siswaNama,
    nis: nis,
    kelasNama: kelasNama,
    semesterId: semesterId,
    semesterNama: semesterNama,
    tahunAjaran: tahunAjaran,
    rataRata: rataRata,
    peringkat: peringkat,
  );
}
