import '../../domain/entities/pendaftaran_ekskul_entity.dart';

/// Model pendaftaran ekstrakurikuler — parsing manual dari
/// `EkstrakurikulerSiswaResource`.
class PendaftaranEkskulModel {
  final int id;
  final int? ekstrakurikulerId;
  final int? siswaId;
  final String? tanggalDaftar;
  final String status;
  final String? ekstrakurikulerNama;
  final String? ekstrakurikulerDeskripsi;
  final String? siswaNama;
  final String? siswaNis;
  final String? siswaNisn;

  const PendaftaranEkskulModel({
    required this.id,
    this.ekstrakurikulerId,
    this.siswaId,
    this.tanggalDaftar,
    this.status = 'aktif',
    this.ekstrakurikulerNama,
    this.ekstrakurikulerDeskripsi,
    this.siswaNama,
    this.siswaNis,
    this.siswaNisn,
  });

  factory PendaftaranEkskulModel.fromJson(Map<String, dynamic> json) {
    final ekskul = json['ekstrakurikuler'] as Map<String, dynamic>?;
    final siswa = json['siswa'] as Map<String, dynamic>?;

    return PendaftaranEkskulModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      ekstrakurikulerId:
          (json['ekstrakurikuler_id'] as num?)?.toInt() ??
          (ekskul?['id'] as num?)?.toInt(),
      siswaId:
          (json['siswa_id'] as num?)?.toInt() ??
          (siswa?['id'] as num?)?.toInt(),
      tanggalDaftar: json['tanggal_daftar'] as String?,
      status: json['status'] as String? ?? 'aktif',
      ekstrakurikulerNama: ekskul?['nama'] as String?,
      ekstrakurikulerDeskripsi: ekskul?['deskripsi'] as String?,
      siswaNama: siswa?['nama'] as String?,
      siswaNis: siswa?['nis'] as String?,
      siswaNisn: siswa?['nisn'] as String?,
    );
  }

  PendaftaranEkskulEntity toEntity() => PendaftaranEkskulEntity(
    id: id,
    ekstrakurikulerId: ekstrakurikulerId,
    siswaId: siswaId,
    tanggalDaftar: tanggalDaftar,
    status: status,
    ekstrakurikulerNama: ekstrakurikulerNama,
    ekstrakurikulerDeskripsi: ekstrakurikulerDeskripsi,
    siswaNama: siswaNama,
    siswaNis: siswaNis,
    siswaNisn: siswaNisn,
  );
}
