import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel {
  final int id;
  final String name;
  final String email;
  final String? photo;
  final List<String> roles;
  final List<String> permissions;

  @JsonKey(name: 'sekolah_id')
  final int? sekolahId;

  @JsonKey(name: 'siswa_id')
  final int? siswaId;

  @JsonKey(name: 'guru_id')
  final int? guruId;

  @JsonKey(name: 'wali_id')
  final int? waliId;

  const UserModel({
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

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

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
}
