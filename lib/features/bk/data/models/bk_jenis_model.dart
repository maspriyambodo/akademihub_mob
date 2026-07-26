import '../../domain/entities/bk_jenis_entity.dart';

/// Model jenis kasus BK — field dari `BkJenisResource`:
/// `id`, `kode`, `nama`, `keterangan`, `created_at`, `updated_at`.
class BkJenisModel {
  final int id;
  final String? kode;
  final String nama;
  final String? keterangan;

  const BkJenisModel({
    required this.id,
    this.kode,
    required this.nama,
    this.keterangan,
  });

  factory BkJenisModel.fromJson(Map<String, dynamic> json) => BkJenisModel(
    id: (json['id'] as num?)?.toInt() ?? 0,
    kode: json['kode']?.toString(),
    nama: json['nama'] as String? ?? '-',
    keterangan: json['keterangan'] as String?,
  );

  BkJenisEntity toEntity() =>
      BkJenisEntity(id: id, kode: kode, nama: nama, keterangan: keterangan);
}
