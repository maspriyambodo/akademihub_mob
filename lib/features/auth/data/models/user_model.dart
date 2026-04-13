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

  bool get isSiswa => role == 'siswa';
  bool get isGuru => role == 'guru';
  bool get isWali => role == 'wali';
  bool get isAdmin => role == 'admin';

  String get primaryRole => role ?? 'unknown';
}
