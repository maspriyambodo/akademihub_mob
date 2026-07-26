import '../../domain/entities/bk_tindakan_entity.dart';

/// Model tindak lanjut — field dari `BkTindakanResource`:
/// `id`, `trx_bk_kasus_id`, `deskripsi_tindakan`, `created_at`, `updated_at`.
class BkTindakanModel {
  final int id;
  final int? kasusId;
  final String? deskripsi;
  final String? createdAt;

  const BkTindakanModel({
    required this.id,
    this.kasusId,
    this.deskripsi,
    this.createdAt,
  });

  factory BkTindakanModel.fromJson(Map<String, dynamic> json) =>
      BkTindakanModel(
        id: (json['id'] as num?)?.toInt() ?? 0,
        kasusId: (json['trx_bk_kasus_id'] as num?)?.toInt(),
        deskripsi: json['deskripsi_tindakan'] as String?,
        createdAt: json['created_at'] as String?,
      );

  BkTindakanEntity toEntity() => BkTindakanEntity(
    id: id,
    kasusId: kasusId,
    deskripsi: deskripsi,
    createdAt: createdAt,
  );
}
