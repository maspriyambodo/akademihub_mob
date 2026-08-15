import 'package:equatable/equatable.dart';

/// Satu item notifikasi in-app (tabel `sys_notifikasi` di backend).
class NotificationEntity extends Equatable {
  final int id;

  /// Jenis notifikasi dari backend:
  /// `ews_alert`, `absensi`, `nilai_anomali`, `spp_tunggakan`,
  /// `tugas_deadline`, `risk_profile`.
  final String type;

  /// Tingkat urgensi: `critical` | `high` | `medium` | `low`.
  final String urgency;

  final String judul;
  final String pesan;

  /// Payload tambahan (kolom jsonb `data`). Bisa null.
  final Map<String, dynamic>? data;

  final bool isRead;
  final DateTime? readAt;
  final DateTime? createdAt;

  const NotificationEntity({
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

  /// Dipakai untuk optimistic update di bloc.
  NotificationEntity copyWith({bool? isRead, DateTime? readAt}) {
    return NotificationEntity(
      id: id,
      type: type,
      urgency: urgency,
      judul: judul,
      pesan: pesan,
      data: data,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [id];
}
