import 'package:equatable/equatable.dart';

import 'kalender_tipe_entity.dart';

/// Event kalender akademik (`trx_kalender_akademik`).
///
/// Catatan penting hasil verifikasi backend:
/// - Event memakai **rentang tanggal**: `tanggal_mulai` (wajib) dan
///   `tanggal_selesai` (nullable). Bila `tanggal_selesai` null → event 1 hari.
/// - `waktu_mulai` / `waktu_selesai` bertipe `time` dan bisa null
///   (format dari Postgres: `HH:mm:ss`).
/// - `status`: 0 = dibatalkan, 1 = aktif, 2 = selesai.
/// - `prioritas`: 1 = tinggi, 2 = normal, 3 = rendah.
class KalenderEventEntity extends Equatable {
  final int id;
  final int? tipeId;

  /// Relasi `tipe` selalu di-eager-load oleh backend pada endpoint index.
  final KalenderTipeEntity? tipe;

  final int? semesterId;
  final String? semesterNama;
  final String? tahunAjaranNama;

  final String judul;
  final String? deskripsi;

  /// Format ternormalisasi "YYYY-MM-DD".
  final String tanggalMulai;

  /// Format ternormalisasi "YYYY-MM-DD"; null bila event hanya satu hari.
  final String? tanggalSelesai;

  /// Format "HH:mm" bila tersedia.
  final String? waktuMulai;
  final String? waktuSelesai;

  final int status;
  final int prioritas;
  final String? lokasi;
  final bool isAllDay;
  final bool isRecurring;

  const KalenderEventEntity({
    required this.id,
    this.tipeId,
    this.tipe,
    this.semesterId,
    this.semesterNama,
    this.tahunAjaranNama,
    required this.judul,
    this.deskripsi,
    required this.tanggalMulai,
    this.tanggalSelesai,
    this.waktuMulai,
    this.waktuSelesai,
    this.status = 1,
    this.prioritas = 2,
    this.lokasi,
    this.isAllDay = false,
    this.isRecurring = false,
  });

  DateTime? get tanggalMulaiDate => DateTime.tryParse(tanggalMulai);

  DateTime? get tanggalSelesaiDate =>
      tanggalSelesai == null ? null : DateTime.tryParse(tanggalSelesai!);

  /// Tanggal akhir efektif — jatuh balik ke tanggal mulai bila tidak ada.
  DateTime? get tanggalAkhirEfektif =>
      tanggalSelesaiDate ?? tanggalMulaiDate;

  bool get isRentang {
    final mulai = tanggalMulaiDate;
    final selesai = tanggalSelesaiDate;
    if (mulai == null || selesai == null) return false;
    return selesai.isAfter(mulai);
  }

  bool get isDibatalkan => status == 0;
  bool get isSelesai => status == 2;
  bool get isPrioritasTinggi => prioritas == 1;

  @override
  List<Object?> get props => [id];
}
