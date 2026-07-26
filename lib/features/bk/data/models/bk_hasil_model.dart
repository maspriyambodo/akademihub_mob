import '../../domain/entities/bk_hasil_entity.dart';

/// Model hasil konseling — field dari `BkHasilResource`:
/// `id`, `trx_bk_kasus_id`, `hasil`, `rekomendasi`, `created_at`, `updated_at`.
class BkHasilModel {
  final int id;
  final int? kasusId;
  final String? hasil;
  final String? rekomendasi;
  final String? createdAt;

  const BkHasilModel({
    required this.id,
    this.kasusId,
    this.hasil,
    this.rekomendasi,
    this.createdAt,
  });

  factory BkHasilModel.fromJson(Map<String, dynamic> json) => BkHasilModel(
    id: (json['id'] as num?)?.toInt() ?? 0,
    kasusId: (json['trx_bk_kasus_id'] as num?)?.toInt(),
    hasil: json['hasil'] as String?,
    rekomendasi: json['rekomendasi'] as String?,
    createdAt: json['created_at'] as String?,
  );

  BkHasilEntity toEntity() => BkHasilEntity(
    id: id,
    kasusId: kasusId,
    hasil: hasil,
    rekomendasi: rekomendasi,
    createdAt: createdAt,
  );
}
