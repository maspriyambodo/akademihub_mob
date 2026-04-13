import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/tenant_entity.dart';

part 'tenant_model.g.dart';

@JsonSerializable()
class TenantModel {
  final String identifier;
  final String name;
  final String subdomain;

  @JsonKey(name: 'api_base_url')
  final String apiBaseUrl;

  @JsonKey(name: 'ws_host')
  final String wsHost;

  @JsonKey(name: 'ws_port')
  final int wsPort;

  @JsonKey(name: 'ws_scheme')
  final String wsScheme;

  @JsonKey(name: 'ws_app_key')
  final String wsAppKey;

  @JsonKey(name: 'logo_url')
  final String? logoUrl;

  @JsonKey(name: 'is_active')
  final bool isActive;

  const TenantModel({
    required this.identifier,
    required this.name,
    required this.subdomain,
    required this.apiBaseUrl,
    required this.wsHost,
    this.wsPort = 8080,
    this.wsScheme = 'wss',
    required this.wsAppKey,
    this.logoUrl,
    this.isActive = true,
  });

  factory TenantModel.fromJson(Map<String, dynamic> json) =>
      _$TenantModelFromJson(json);

  Map<String, dynamic> toJson() => _$TenantModelToJson(this);

  TenantEntity toEntity() => TenantEntity(
    identifier: identifier,
    name: name,
    subdomain: subdomain,
    apiBaseUrl: apiBaseUrl,
    wsHost: wsHost,
    wsPort: wsPort,
    wsScheme: wsScheme,
    wsAppKey: wsAppKey,
    logoUrl: logoUrl,
    isActive: isActive,
  );
}
