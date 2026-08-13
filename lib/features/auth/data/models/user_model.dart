import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel {
  final int id;
  final String name;
  final String email;

  /// Kode role utama, misal: "siswa", "guru", "wali", "admin"
  final String? role;

  @JsonKey(name: 'is_active')
  final bool isActive;

  /// Daftar permission codes, digabung dari roles[].permissions[].code
  @JsonKey(fromJson: _permissionsFromJson)
  final List<String> permissions;

  /// Data profil sesuai role (guru/siswa/wali) — struktur bervariasi
  final Map<String, dynamic>? profile;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.role,
    this.isActive = true,
    this.permissions = const [],
    this.profile,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  bool get isSiswa => role?.toUpperCase() == 'SISWA';
  bool get isGuru => role?.toUpperCase() == 'GURU';
  bool get isWali => {'WALI', 'WALI_SISWA'}.contains(role?.toUpperCase());
  bool get isAdmin => {
    'ADMIN',
    'ADMIN_SEKOLAH',
    'SUPER_ADMIN',
    'SUPERADMIN',
  }.contains(role?.toUpperCase());

  String get normalizedRole {
    switch (role?.toUpperCase()) {
      case 'SISWA':
        return 'siswa';
      case 'GURU':
        return 'guru';
      case 'WALI':
      case 'WALI_SISWA':
        return 'wali';
      case 'ADMIN':
      case 'ADMIN_SEKOLAH':
      case 'SUPER_ADMIN':
      case 'SUPERADMIN':
        return 'admin';
      default:
        return 'unknown';
    }
  }

  String get primaryRole => role ?? 'unknown';
}

List<String> _permissionsFromJson(List<dynamic>? permissions) =>
    (permissions ?? const []).map((permission) {
      if (permission is String) return permission;
      if (permission case {'code': final String code}) return code;
      throw const FormatException('Invalid permission response');
    }).toList();
