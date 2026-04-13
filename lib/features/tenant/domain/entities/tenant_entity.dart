import 'package:equatable/equatable.dart';
import '../../../../core/config/tenant_config.dart';

/// Domain entity: info sekolah yang dikembalikan API resolve
class TenantEntity extends Equatable {
  final String identifier;
  final String name;
  final String subdomain;
  final String apiBaseUrl;
  final String wsHost;
  final int wsPort;
  final String wsScheme;
  final String wsAppKey;
  final String? logoUrl;
  final bool isActive;

  const TenantEntity({
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

  TenantConfig toConfig() => TenantConfig(
    identifier: identifier,
    name: name,
    apiBaseUrl: apiBaseUrl,
    wsHost: wsHost,
    wsPort: wsPort,
    wsScheme: wsScheme,
    wsAppKey: wsAppKey,
    logoUrl: logoUrl,
  );

  @override
  List<Object?> get props => [identifier, subdomain, apiBaseUrl];
}
