// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  username: json['username'] as String?,
  email: json['email'] as String,
  tenant: json['tenant'] == null
      ? null
      : TenantModel.fromJson(json['tenant'] as Map<String, dynamic>),
  role: json['role'] as String?,
  isActive: json['is_active'] as bool? ?? true,
  permissions: json['permissions'] == null
      ? const []
      : _permissionsFromJson(json['permissions'] as List?),
  profile: json['profile'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'username': instance.username,
  'email': instance.email,
  'tenant': instance.tenant,
  'role': instance.role,
  'is_active': instance.isActive,
  'permissions': instance.permissions,
  'profile': instance.profile,
};

TenantModel _$TenantModelFromJson(Map<String, dynamic> json) => TenantModel(
  id: (json['id'] as num).toInt(),
  uuid: json['uuid'] as String,
  slug: json['slug'] as String?,
  name: json['name'] as String,
  logoPath: json['logo_path'] as String?,
);

Map<String, dynamic> _$TenantModelToJson(TenantModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'uuid': instance.uuid,
      'slug': instance.slug,
      'name': instance.name,
      'logo_path': instance.logoPath,
    };
