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
  final String? jadwalJamPulang;
  final String? shiftNama;
  final bool terlambat;
  final int menitTerlambat;

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
    this.jadwalJamPulang,
    this.shiftNama,
    this.terlambat = false,
    this.menitTerlambat = 0,
  });

  factory AbsensiSiswaModel.fromJson(Map<String, dynamic> json) {
    final siswa = json['siswa'] as Map<String, dynamic>?;
    final shift = json['shift'] as Map<String, dynamic>?;
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
      jadwalJamPulang: json['jadwal_jam_pulang'] as String?,
      shiftNama: shift?['nama'] as String?,
      terlambat: json['terlambat'] as bool? ?? false,
      menitTerlambat: (json['menit_terlambat'] as num?)?.toInt() ?? 0,
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
    jadwalJamPulang: jadwalJamPulang,
    shiftNama: shiftNama,
    terlambat: terlambat,
    menitTerlambat: menitTerlambat,
  );
}
