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
  final String? jadwalJamMasuk;
  final String? shiftKode;
  final String? shiftNama;
  final String? timezone;
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
    this.jadwalJamMasuk,
    this.shiftKode,
    this.shiftNama,
    this.timezone,
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
      statusAbsensi: _status(json),
      keterangan: json['keterangan'] as String?,
      jamMasuk: json['jam_masuk'] as String?,
      jamPulang: json['jam_pulang'] as String?,
      jadwalJamPulang: json['jadwal_jam_pulang'] as String?,
      jadwalJamMasuk: json['jadwal_jam_masuk'] as String?,
      shiftKode: shift?['kode'] as String?,
      shiftNama: shift?['nama'] as String?,
      timezone: json['timezone'] as String?,
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
    jadwalJamMasuk: jadwalJamMasuk,
    shiftKode: shiftKode,
    shiftNama: shiftNama,
    timezone: timezone,
    terlambat: terlambat,
    menitTerlambat: menitTerlambat,
  );

  static String _status(Map<String, dynamic> json) {
    final label = json['status_absensi'];
    if (label is String && label.isNotEmpty) return label;
    return switch ((json['status'] as num?)?.toInt()) {
      1 => 'Hadir',
      2 => 'Sakit',
      3 => 'Izin',
      4 => 'Alpha',
      _ => '',
    };
  }
}
