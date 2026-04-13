// GENERATED CODE - DO NOT MODIFY BY HAND
// Run: flutter pub run build_runner build --delete-conflicting-outputs

part of 'tenant_model.dart';

TenantModel _$TenantModelFromJson(Map<String, dynamic> json) => TenantModel(
  identifier: json['identifier'] as String,
  name: json['name'] as String,
  subdomain: json['subdomain'] as String,
  apiBaseUrl: json['api_base_url'] as String,
  wsHost: json['ws_host'] as String,
  wsPort: json['ws_port'] as int? ?? 8080,
  wsScheme: json['ws_scheme'] as String? ?? 'wss',
  wsAppKey: json['ws_app_key'] as String,
  logoUrl: json['logo_url'] as String?,
  isActive: json['is_active'] as bool? ?? true,
);

Map<String, dynamic> _$TenantModelToJson(TenantModel instance) =>
    <String, dynamic>{
      'identifier': instance.identifier,
      'name': instance.name,
      'subdomain': instance.subdomain,
      'api_base_url': instance.apiBaseUrl,
      'ws_host': instance.wsHost,
      'ws_port': instance.wsPort,
      'ws_scheme': instance.wsScheme,
      'ws_app_key': instance.wsAppKey,
      'logo_url': instance.logoUrl,
      'is_active': instance.isActive,
    };
