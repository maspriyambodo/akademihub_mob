import '../../domain/entities/sekolah_entity.dart';

/// Bentuk JSON mengikuti `App\Http\Resources\Api\V1\SekolahResource`:
/// `{ id, uuid, npsn, nama_sekolah, alamat, logo_path, is_active,
///    subscription_plan, settings?, created_at, updated_at }`
class SekolahModel {
  final int? id;
  final String? uuid;
  final String? npsn;
  final String namaSekolah;
  final String? alamat;
  final String? logoPath;
  final String? subscriptionPlan;
  final bool isActive;

  const SekolahModel({
    this.id,
    this.uuid,
    this.npsn,
    required this.namaSekolah,
    this.alamat,
    this.logoPath,
    this.subscriptionPlan,
    this.isActive = true,
  });

  factory SekolahModel.fromJson(Map<String, dynamic> json) {
    return SekolahModel(
      id: (json['id'] as num?)?.toInt(),
      uuid: json['uuid'] as String?,
      npsn: json['npsn'] as String?,
      namaSekolah: json['nama_sekolah'] as String? ?? '-',
      alamat: json['alamat'] as String?,
      logoPath: json['logo_path'] as String?,
      subscriptionPlan: json['subscription_plan'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  /// Dibuat dari tenant yang tersimpan di perangkat (`TenantConfig`).
  /// Hanya nama & logo yang tersedia — `id`/`npsn`/`alamat` tetap null.
  const SekolahModel.fromTenant({required this.namaSekolah, this.logoPath})
    : id = null,
      uuid = null,
      npsn = null,
      alamat = null,
      subscriptionPlan = null,
      isActive = true;

  SekolahEntity toEntity() => SekolahEntity(
    id: id,
    uuid: uuid,
    npsn: npsn,
    namaSekolah: namaSekolah,
    alamat: alamat,
    logoUrl: logoPath,
    subscriptionPlan: subscriptionPlan,
    isActive: isActive,
  );
}
