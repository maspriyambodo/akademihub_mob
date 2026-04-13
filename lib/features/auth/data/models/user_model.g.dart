// GENERATED CODE - DO NOT MODIFY BY HAND
// Run: flutter pub run build_runner build --delete-conflicting-outputs

part of 'user_model.dart';

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  email: json['email'] as String,
  role: json['role'] as String?,
  isActive: json['is_active'] as bool? ?? true,
  // Flatten permissions from roles[].permissions[].code
  // Backend may return permissions as {} (empty object) instead of [] — guard for both
  permissions: (json['roles'] as List<dynamic>? ?? []).expand((r) {
    final perms = (r as Map<String, dynamic>)['permissions'];
    if (perms is! List) return <String>[];
    return (perms as List<dynamic>).map(
      (p) => (p as Map<String, dynamic>)['code'] as String,
    );
  }).toList(),
  profile: json['profile'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'email': instance.email,
  'role': instance.role,
  'is_active': instance.isActive,
  'permissions': instance.permissions,
  'profile': instance.profile,
};
