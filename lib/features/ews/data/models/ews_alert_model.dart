import '../../domain/entities/ews_alert_entity.dart';

/// Model JSON untuk EWS alert.
///
/// Bentuk payload dari `GET /api/v1/ews` (lihat `docs/MODUL_EWS.md`).
class EwsAlertModel {
  final int id;
  final int siswaId;
  final String kategori;
  final int level;
  final String pesan;
  final Map<String, dynamic>? dataPendukung;
  final bool isResolved;
  final String? resolvedBy;
  final DateTime? resolvedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const EwsAlertModel({
    required this.id,
    required this.siswaId,
    required this.kategori,
    required this.level,
    required this.pesan,
    this.dataPendukung,
    required this.isResolved,
    this.resolvedBy,
    this.resolvedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory EwsAlertModel.fromJson(Map<String, dynamic> json) {
    return EwsAlertModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      siswaId: (json['mst_siswa_id'] as num?)?.toInt() ?? 0,
      kategori: json['kategori'] as String? ?? '',
      level: (json['level'] as num?)?.toInt() ?? 1,
      pesan: json['pesan'] as String? ?? '',
      dataPendukung: _parseData(json['data_pendukung']),
      isResolved: _parseBool(json['is_resolved']),
      resolvedBy: json['resolved_by']?.toString(),
      resolvedAt: _parseDate(json['resolved_at']),
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  EwsAlertEntity toEntity() => EwsAlertEntity(
    id: id,
    siswaId: siswaId,
    kategori: kategori,
    level: level,
    pesan: pesan,
    dataPendukung: dataPendukung,
    isResolved: isResolved,
    resolvedBy: resolvedBy,
    resolvedAt: resolvedAt,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );

  static Map<String, dynamic>? _parseData(dynamic raw) {
    if (raw is Map) {
      return raw.map((k, v) => MapEntry(k.toString(), v));
    }
    return null;
  }

  static bool _parseBool(dynamic raw) {
    if (raw is bool) return raw;
    if (raw is num) return raw != 0;
    if (raw is String) {
      final v = raw.toLowerCase();
      return v == 'true' || v == '1' || v == 't';
    }
    return false;
  }

  static DateTime? _parseDate(dynamic raw) {
    if (raw is! String || raw.isEmpty) return null;
    return DateTime.tryParse(raw)?.toLocal();
  }
}
