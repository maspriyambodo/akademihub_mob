import 'package:equatable/equatable.dart';

/// Alert EWS untuk satu siswa.
///
/// Bersumber dari `GET /api/v1/ews` (lihat `docs/MODUL_EWS.md`).
class EwsAlertEntity extends Equatable {
  final int id;
  final int siswaId;
  final String kategori; // 'absensi' | 'nilai' | 'perilaku'
  final int level; // 1 | 2 | 3
  final String pesan;
  final Map<String, dynamic>? dataPendukung;
  final bool isResolved;
  final String? resolvedBy;
  final DateTime? resolvedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const EwsAlertEntity({
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

  /// Label kategori singkat untuk UI.
  String get kategoriLabel {
    switch (kategori) {
      case 'absensi':
        return 'Kehadiran';
      case 'nilai':
        return 'Akademik';
      case 'perilaku':
        return 'Perilaku';
      default:
        return kategori;
    }
  }

  /// Label level risiko.
  String get levelLabel {
    switch (level) {
      case 1:
        return 'Ringan';
      case 2:
        return 'Sedang';
      case 3:
        return 'Berat';
      default:
        return 'Level $level';
    }
  }

  DateTime? get tanggal {
    return createdAt;
  }

  @override
  List<Object?> get props => [
    id,
    siswaId,
    kategori,
    level,
    pesan,
    isResolved,
    createdAt,
  ];
}
