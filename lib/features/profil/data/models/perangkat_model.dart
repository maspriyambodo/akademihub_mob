import '../../domain/entities/perangkat_entity.dart';

/// `SysUserDeviceController@byUser` mengembalikan model Eloquent apa adanya
/// (tanpa Resource), jadi key JSON = nama kolom tabel `sys_user_devices`:
/// `{ id, sys_user_id, fcm_token, device_type, app_version, last_active_at,
///    created_at }`.
///
/// `fcm_token` sengaja TIDAK dipetakan ke entity — tidak ada gunanya
/// ditampilkan di UI dan sebaiknya tidak dibawa-bawa di memori.
class PerangkatModel {
  final int id;
  final int? userId;
  final String? deviceType;
  final String? appVersion;
  final String? lastActiveAt;
  final String? createdAt;

  const PerangkatModel({
    required this.id,
    this.userId,
    this.deviceType,
    this.appVersion,
    this.lastActiveAt,
    this.createdAt,
  });

  factory PerangkatModel.fromJson(Map<String, dynamic> json) {
    return PerangkatModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      userId: (json['sys_user_id'] as num?)?.toInt(),
      deviceType: json['device_type'] as String?,
      appVersion: json['app_version'] as String?,
      lastActiveAt: json['last_active_at'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  static DateTime? _parse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw)?.toLocal();
  }

  PerangkatEntity toEntity() => PerangkatEntity(
    id: id,
    userId: userId,
    deviceType: deviceType,
    appVersion: appVersion,
    lastActiveAt: _parse(lastActiveAt),
    createdAt: _parse(createdAt),
  );
}
