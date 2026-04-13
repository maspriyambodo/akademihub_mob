import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final int id;
  final String name;
  final String email;
  final String? photo;
  final List<String> roles;
  final List<String> permissions;
  final int? sekolahId;
  final int? siswaId;
  final int? guruId;
  final int? waliId;

  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
    this.photo,
    required this.roles,
    required this.permissions,
    this.sekolahId,
    this.siswaId,
    this.guruId,
    this.waliId,
  });

  bool get isSiswa => roles.contains('siswa');
  bool get isGuru => roles.contains('guru');
  bool get isWali => roles.contains('wali');
  bool get isAdmin => roles.contains('admin');

  String get primaryRole {
    if (isAdmin) return 'admin';
    if (isGuru) return 'guru';
    if (isWali) return 'wali';
    if (isSiswa) return 'siswa';
    return 'unknown';
  }

  bool hasPermission(String permission) => permissions.contains(permission);

  @override
  List<Object?> get props => [id, email, roles];
}
