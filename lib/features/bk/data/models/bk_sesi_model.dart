import '../../domain/entities/bk_sesi_entity.dart';

/// Model sesi konseling — field dari `BkSesiResource`:
/// `id`, `trx_bk_kasus_id`, `tanggal`, `metode` (label), `catatan`,
/// `created_at`, `updated_at`.
class BkSesiModel {
  final int id;
  final int? kasusId;
  final String? tanggal;
  final String? metode;
  final String? catatan;
  final String? createdAt;

  const BkSesiModel({
    required this.id,
    this.kasusId,
    this.tanggal,
    this.metode,
    this.catatan,
    this.createdAt,
  });

  factory BkSesiModel.fromJson(Map<String, dynamic> json) => BkSesiModel(
    id: (json['id'] as num?)?.toInt() ?? 0,
    kasusId: (json['trx_bk_kasus_id'] as num?)?.toInt(),
    tanggal: json['tanggal']?.toString(),
    metode: json['metode']?.toString(),
    catatan: json['catatan'] as String?,
    createdAt: json['created_at'] as String?,
  );

  BkSesiEntity toEntity() => BkSesiEntity(
    id: id,
    kasusId: kasusId,
    tanggal: tanggal,
    metode: metode,
    catatan: catatan,
    createdAt: createdAt,
  );
}
