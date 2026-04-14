import '../../domain/entities/absensi_guru_entity.dart';

class AbsensiGuruModel {
  final int id;
  final int? guruId;
  final String? guruNama;
  final String? guruNip;
  final String tanggal;
  final String statusAbsensi;
  final String? keterangan;
  final String? jamMasuk;
  final String? jamKeluar;

  const AbsensiGuruModel({
    required this.id,
    this.guruId,
    this.guruNama,
    this.guruNip,
    required this.tanggal,
    required this.statusAbsensi,
    this.keterangan,
    this.jamMasuk,
    this.jamKeluar,
  });

  factory AbsensiGuruModel.fromJson(Map<String, dynamic> json) {
    final guru = json['guru'] as Map<String, dynamic>?;
    return AbsensiGuruModel(
      id: (json['id'] as num).toInt(),
      guruId: guru != null ? (guru['id'] as num?)?.toInt() : null,
      guruNama: guru?['nama'] as String?,
      guruNip: guru?['nip'] as String?,
      tanggal: json['tanggal'] as String? ?? '',
      statusAbsensi: json['status_absensi'] as String? ?? '',
      keterangan: json['keterangan'] as String?,
      jamMasuk: json['jam_masuk'] as String?,
      jamKeluar: json['jam_keluar'] as String?,
    );
  }

  AbsensiGuruEntity toEntity() => AbsensiGuruEntity(
    id: id,
    guruId: guruId,
    guruNama: guruNama,
    guruNip: guruNip,
    tanggal: tanggal,
    statusAbsensi: statusAbsensi,
    keterangan: keterangan,
    jamMasuk: jamMasuk,
    jamKeluar: jamKeluar,
  );
}
