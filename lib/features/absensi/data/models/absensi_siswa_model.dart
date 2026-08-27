import '../../domain/entities/absensi_siswa_entity.dart';

class AbsensiSiswaModel {
  final int id;
  final int? siswaId;
  final String? siswaNama;
  final String? siswaNis;
  final String tanggal;
  final String statusAbsensi;
  final String? keterangan;
  final String? jamMasuk;
  final String? jamPulang;

  const AbsensiSiswaModel({
    required this.id,
    this.siswaId,
    this.siswaNama,
    this.siswaNis,
    required this.tanggal,
    required this.statusAbsensi,
    this.keterangan,
    this.jamMasuk,
    this.jamPulang,
  });

  factory AbsensiSiswaModel.fromJson(Map<String, dynamic> json) {
    final siswa = json['siswa'] as Map<String, dynamic>?;
    return AbsensiSiswaModel(
      id: (json['id'] as num).toInt(),
      siswaId: siswa != null ? (siswa['id'] as num?)?.toInt() : null,
      siswaNama: siswa?['nama'] as String?,
      siswaNis: siswa?['nis'] as String?,
      tanggal: json['tanggal'] as String? ?? '',
      statusAbsensi: json['status_absensi'] as String? ?? '',
      keterangan: json['keterangan'] as String?,
      jamMasuk: json['jam_masuk'] as String?,
      jamPulang: json['jam_pulang'] as String?,
    );
  }

  AbsensiSiswaEntity toEntity() => AbsensiSiswaEntity(
    id: id,
    siswaId: siswaId,
    siswaNama: siswaNama,
    siswaNis: siswaNis,
    tanggal: tanggal,
    statusAbsensi: statusAbsensi,
    keterangan: keterangan,
    jamMasuk: jamMasuk,
    jamPulang: jamPulang,
  );
}
