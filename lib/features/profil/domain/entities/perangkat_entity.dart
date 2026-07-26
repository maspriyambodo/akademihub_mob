import 'package:equatable/equatable.dart';

/// Satu perangkat yang pernah dipakai user untuk login / menerima notifikasi.
/// Berasal dari tabel `sys_user_devices`.
class PerangkatEntity extends Equatable {
  final int id;
  final int? userId;

  /// `android` | `ios` | `web` (kolom `device_type`, nullable di DB)
  final String? deviceType;

  /// Versi aplikasi saat perangkat didaftarkan (kolom `app_version`)
  final String? appVersion;

  final DateTime? lastActiveAt;
  final DateTime? createdAt;

  const PerangkatEntity({
    required this.id,
    this.userId,
    this.deviceType,
    this.appVersion,
    this.lastActiveAt,
    this.createdAt,
  });

  @override
  List<Object?> get props => [id];
}
