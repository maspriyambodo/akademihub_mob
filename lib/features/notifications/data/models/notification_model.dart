import '../../domain/entities/notification_entity.dart';

/// Bentuk JSON dari `SysNotifikasiController::formatNotif()`:
/// ```json
/// {
///   "id": 1, "type": "absensi", "urgency": "high",
///   "judul": "...", "pesan": "...", "data": {...},
///   "is_read": false, "read_at": null, "created_at": "2026-07-26T..."
/// }
/// ```
class NotificationModel {
  final int id;
  final String type;
  final String urgency;
  final String judul;
  final String pesan;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime? readAt;
  final DateTime? createdAt;

  const NotificationModel({
    required this.id,
    required this.type,
    required this.urgency,
    required this.judul,
    required this.pesan,
    this.data,
    required this.isRead,
    this.readAt,
    this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      type: json['type'] as String? ?? '',
      urgency: json['urgency'] as String? ?? '',
      judul: json['judul'] as String? ?? '',
      pesan: json['pesan'] as String? ?? '',
      data: _parseData(json['data']),
      isRead: _parseBool(json['is_read']),
      readAt: _parseDate(json['read_at']),
      createdAt: _parseDate(json['created_at']),
    );
  }

  NotificationEntity toEntity() => NotificationEntity(
    id: id,
    type: type,
    urgency: urgency,
    judul: judul,
    pesan: pesan,
    data: data,
    isRead: isRead,
    readAt: readAt,
    createdAt: createdAt,
  );

  /// Kolom `data` di-cast `array` oleh Eloquent, tapi tetap dijaga null-safe
  /// kalau backend mengirim list / nilai lain.
  static Map<String, dynamic>? _parseData(dynamic raw) {
    if (raw is Map) {
      return raw.map((k, v) => MapEntry(k.toString(), v));
    }
    return null;
  }

  /// Postgres boolean bisa datang sebagai bool, int, atau string.
  static bool _parseBool(dynamic raw) {
    if (raw is bool) return raw;
    if (raw is num) return raw != 0;
    if (raw is String) {
      final v = raw.toLowerCase();
      return v == 'true' || v == '1' || v == 't';
    }
    return false;
  }

  /// Backend mengirim ISO-8601 (`toISOString()`), tapi tetap toleran null.
  static DateTime? _parseDate(dynamic raw) {
    if (raw is! String || raw.isEmpty) return null;
    return DateTime.tryParse(raw)?.toLocal();
  }
}
