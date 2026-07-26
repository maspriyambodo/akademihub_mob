import '../../domain/entities/kelas_option_entity.dart';

/// Model ringkas `KelasResource` (`GET /kelas`).
class KelasOptionModel {
  final int id;
  final String namaKelas;
  final int? tingkat;
  final int? tahunAjaranId;
  final String? tahunAjaranNama;

  const KelasOptionModel({
    required this.id,
    required this.namaKelas,
    this.tingkat,
    this.tahunAjaranId,
    this.tahunAjaranNama,
  });

  factory KelasOptionModel.fromJson(Map<String, dynamic> json) {
    return KelasOptionModel(
      id: (json['id'] as num).toInt(),
      namaKelas: json['nama_kelas'] as String? ?? '',
      tingkat: (json['tingkat'] as num?)?.toInt(),
      tahunAjaranId: (json['tahun_ajaran_id'] as num?)?.toInt(),
      tahunAjaranNama: json['tahun_ajaran'] as String?,
    );
  }

  KelasOptionEntity toEntity() => KelasOptionEntity(
    id: id,
    namaKelas: namaKelas,
    tingkat: tingkat,
    tahunAjaranId: tahunAjaranId,
    tahunAjaranNama: tahunAjaranNama,
  );
}
