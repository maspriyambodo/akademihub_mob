import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final int id;
  final String name;
  final String email;

  /// Kode role utama, misal: "siswa", "guru", "wali", "admin"
  final String? role;

  final bool isActive;
  final List<String> permissions;
  final Map<String, dynamic>? profile;

  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
    this.role,
    this.isActive = true,
    this.permissions = const [],
    this.profile,
  });

  bool get isSiswa => role == 'siswa';
  bool get isGuru => role == 'guru';
  bool get isWali => role == 'wali';
  bool get isAdmin => role == 'admin';

  String get primaryRole => role ?? 'unknown';

  bool hasPermission(String permission) => permissions.contains(permission);

  @override
  List<Object?> get props => [id, email, role];
}
