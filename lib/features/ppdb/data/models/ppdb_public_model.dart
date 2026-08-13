import '../../domain/entities/ppdb_public_entity.dart';
import 'ppdb_parse_utils.dart';

class PpdbSekolahModel {
  final int id;
  final String nama;

  const PpdbSekolahModel({required this.id, required this.nama});

  factory PpdbSekolahModel.fromJson(Map<String, dynamic> json) =>
      PpdbSekolahModel(
        id: parseIntOrNull(json['id']) ?? 0,
        nama: json['nama_sekolah']?.toString() ?? '',
      );

  PpdbSekolahEntity toEntity() => PpdbSekolahEntity(id: id, nama: nama);
}

class PpdbStatusPublikModel {
  final String noPendaftaran;
  final String namaLengkap;
  final String status;
  final String? namaGelombang;
  final DateTime? tanggalDaftar;

  const PpdbStatusPublikModel({
    required this.noPendaftaran,
    required this.namaLengkap,
    required this.status,
    this.namaGelombang,
    this.tanggalDaftar,
  });

  factory PpdbStatusPublikModel.fromJson(Map<String, dynamic> json) {
    final gelombang = json['gelombang'];
    return PpdbStatusPublikModel(
      noPendaftaran: json['no_pendaftaran']?.toString() ?? '',
      namaLengkap: json['nama_lengkap']?.toString() ?? '',
      status: json['status_pendaftaran']?.toString() ?? '',
      namaGelombang: gelombang is Map
          ? gelombang['nama_gelombang']?.toString()
          : gelombang?.toString(),
      tanggalDaftar: DateTime.tryParse(
        json['tanggal_daftar']?.toString() ?? '',
      )?.toLocal(),
    );
  }

  PpdbStatusPublikEntity toEntity() => PpdbStatusPublikEntity(
    noPendaftaran: noPendaftaran,
    namaLengkap: namaLengkap,
    status: status,
    namaGelombang: namaGelombang,
    tanggalDaftar: tanggalDaftar,
  );
}

class PpdbPendaftaranPublikModel {
  final String noPendaftaran;
  final String namaLengkap;
  final String status;

  const PpdbPendaftaranPublikModel({
    required this.noPendaftaran,
    required this.namaLengkap,
    required this.status,
  });

  factory PpdbPendaftaranPublikModel.fromJson(Map<String, dynamic> json) =>
      PpdbPendaftaranPublikModel(
        noPendaftaran: json['no_pendaftaran']?.toString() ?? '',
        namaLengkap: json['nama_lengkap']?.toString() ?? '',
        status: json['status_pendaftaran']?.toString() ?? '',
      );

  PpdbPendaftaranPublikEntity toEntity() => PpdbPendaftaranPublikEntity(
    noPendaftaran: noPendaftaran,
    namaLengkap: namaLengkap,
    status: status,
  );
}
