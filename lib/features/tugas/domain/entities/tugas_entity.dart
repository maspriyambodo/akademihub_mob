import 'package:equatable/equatable.dart';

/// Entity untuk satu tugas (tabel `mst_tugas`).
class TugasEntity extends Equatable {
  final int id;

  /// `mst_guru_mapel_id`
  final int? guruMapelId;

  /// `mst_kelas_id`
  final int? kelasId;

  final String judul;
  final String? deskripsi;

  /// URL / path lampiran dari guru (`file_lampiran`)
  final String? fileLampiran;

  /// ISO8601, mis. "2026-08-01T23:59:00+07:00"
  final String? tenggatWaktu;

  /// 1 = Aktif, selain itu Draft/Selesai
  final int? status;
  final String? statusLabel;

  // ── Relasi guru_mapel ──────────────────────────────────────────────────────
  final int? guruId;
  final String? guruNama;
  final String? mapelKode;
  final String? mapelNama;

  // ── Relasi kelas ───────────────────────────────────────────────────────────
  final String? kelasNama;
  final String? kelasLevel;

  const TugasEntity({
    required this.id,
    this.guruMapelId,
    this.kelasId,
    required this.judul,
    this.deskripsi,
    this.fileLampiran,
    this.tenggatWaktu,
    this.status,
    this.statusLabel,
    this.guruId,
    this.guruNama,
    this.mapelKode,
    this.mapelNama,
    this.kelasNama,
    this.kelasLevel,
  });

  DateTime? get tenggatWaktuDate =>
      tenggatWaktu == null ? null : DateTime.tryParse(tenggatWaktu!);

  /// Sudah lewat deadline (dihitung dari waktu perangkat).
  bool get isLewatDeadline {
    final d = tenggatWaktuDate;
    if (d == null) return false;
    return DateTime.now().isAfter(d);
  }

  /// Deadline kurang dari 2 hari lagi dan belum lewat.
  bool get isMendekatiDeadline {
    final d = tenggatWaktuDate;
    if (d == null) return false;
    final selisih = d.difference(DateTime.now());
    return !selisih.isNegative && selisih.inHours <= 48;
  }

  /// Sisa hari menuju deadline (negatif bila sudah lewat).
  int? get sisaHari {
    final d = tenggatWaktuDate;
    if (d == null) return null;
    return d.difference(DateTime.now()).inHours ~/ 24;
  }

  String get mapelLabel {
    if (mapelNama != null && mapelNama!.isNotEmpty) return mapelNama!;
    if (mapelKode != null && mapelKode!.isNotEmpty) return mapelKode!;
    return 'Umum';
  }

  @override
  List<Object?> get props => [id];
}
