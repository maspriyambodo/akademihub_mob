import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final int id;
  final String name;
  final String? username;
  final String email;
  final TenantEntity? tenant;

  /// Kode role utama, misal: "siswa", "guru", "wali", "admin"
  final String? role;

  final bool isActive;
  final List<String> permissions;
  final Map<String, dynamic>? profile;

  const UserEntity({
    required this.id,
    required this.name,
    this.username,
    required this.email,
    this.tenant,
    this.role,
    this.isActive = true,
    this.permissions = const [],
    this.profile,
  });

  bool get isSiswa => role == 'siswa';
  bool get isGuru => role == 'guru';
  bool get isWali => role == 'wali';
  bool get isAdmin => role == 'admin';
  bool get isSuperAdmin => (role ?? '').toLowerCase() == 'superadmin';

  String get primaryRole => role ?? 'unknown';

  int? get profileId {
    final nestedProfile = profile?['siswa'];
    final value =
        profile?['mst_siswa_id'] ??
        profile?['siswa_id'] ??
        (nestedProfile is Map ? nestedProfile['id'] : null) ??
        profile?['id'];
    return value is int ? value : int.tryParse('$value');
  }

  bool hasPermission(String permission) => permissions.contains(permission);

  @override
  List<Object?> get props => [id, username, email, role, tenant];
}

class TenantEntity extends Equatable {
  final int id;
  final String uuid;
  final String? slug;
  final String name;
  final String? logoPath;

  const TenantEntity({
    required this.id,
    required this.uuid,
    this.slug,
    required this.name,
    this.logoPath,
  });

  @override
  List<Object?> get props => [id, uuid, slug, name, logoPath];
}
