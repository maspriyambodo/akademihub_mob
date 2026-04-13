// GENERATED CODE - DO NOT MODIFY BY HAND
// Run: flutter pub run build_runner build --delete-conflicting-outputs

part of 'user_model.dart';

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  email: json['email'] as String,
  photo: json['photo'] as String?,
  roles: (json['roles'] as List<dynamic>).map((e) => e as String).toList(),
  permissions: (json['permissions'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  sekolahId: (json['sekolah_id'] as num?)?.toInt(),
  siswaId: (json['siswa_id'] as num?)?.toInt(),
  guruId: (json['guru_id'] as num?)?.toInt(),
  waliId: (json['wali_id'] as num?)?.toInt(),
);

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'email': instance.email,
  'photo': instance.photo,
  'roles': instance.roles,
  'permissions': instance.permissions,
  'sekolah_id': instance.sekolahId,
  'siswa_id': instance.siswaId,
  'guru_id': instance.guruId,
  'wali_id': instance.waliId,
};
