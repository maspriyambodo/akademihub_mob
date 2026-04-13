import 'package:equatable/equatable.dart';

/// Konfigurasi runtime per-tenant (per-sekolah).
/// Disimpan di storage setelah user memilih/mengonfirmasi sekolah.
class TenantConfig extends Equatable {
  /// Identifier unik sekolah, misal: "smkn1bdg"
  final String identifier;

  /// Nama lengkap sekolah
  final String name;

  /// Base URL API, misal: "https://smkn1bdg.akademihub.id/api"
  final String apiBaseUrl;

  /// Host WebSocket Reverb, misal: "smkn1bdg.akademihub.id"
  final String wsHost;

  /// Port WebSocket (default 8080)
  final int wsPort;

  /// Scheme WebSocket ("wss" atau "ws")
  final String wsScheme;

  /// Pusher/Reverb app key milik tenant ini
  final String wsAppKey;

  /// URL logo sekolah (opsional)
  final String? logoUrl;

  const TenantConfig({
    required this.identifier,
    required this.name,
    required this.apiBaseUrl,
    required this.wsHost,
    this.wsPort = 8080,
    this.wsScheme = 'wss',
    required this.wsAppKey,
    this.logoUrl,
  });

  String get wsUrl => '$wsScheme://$wsHost:$wsPort';

  TenantConfig copyWith({
    String? identifier,
    String? name,
    String? apiBaseUrl,
    String? wsHost,
    int? wsPort,
    String? wsScheme,
    String? wsAppKey,
    String? logoUrl,
  }) {
    return TenantConfig(
      identifier: identifier ?? this.identifier,
      name: name ?? this.name,
      apiBaseUrl: apiBaseUrl ?? this.apiBaseUrl,
      wsHost: wsHost ?? this.wsHost,
      wsPort: wsPort ?? this.wsPort,
      wsScheme: wsScheme ?? this.wsScheme,
      wsAppKey: wsAppKey ?? this.wsAppKey,
      logoUrl: logoUrl ?? this.logoUrl,
    );
  }

  Map<String, dynamic> toJson() => {
    'identifier': identifier,
    'name': name,
    'apiBaseUrl': apiBaseUrl,
    'wsHost': wsHost,
    'wsPort': wsPort,
    'wsScheme': wsScheme,
    'wsAppKey': wsAppKey,
    'logoUrl': logoUrl,
  };

  factory TenantConfig.fromJson(Map<String, dynamic> json) => TenantConfig(
    identifier: json['identifier'] as String,
    name: json['name'] as String,
    apiBaseUrl: json['apiBaseUrl'] as String,
    wsHost: json['wsHost'] as String,
    wsPort: json['wsPort'] as int? ?? 8080,
    wsScheme: json['wsScheme'] as String? ?? 'wss',
    wsAppKey: json['wsAppKey'] as String,
    logoUrl: json['logoUrl'] as String?,
  );

  @override
  List<Object?> get props => [
    identifier,
    name,
    apiBaseUrl,
    wsHost,
    wsPort,
    wsScheme,
    wsAppKey,
  ];
}
