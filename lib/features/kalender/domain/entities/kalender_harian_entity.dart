import 'package:equatable/equatable.dart';

/// Agenda harian (`trx_kalender_harian`).
///
/// Struktur backend: baris harian SELALU menempel ke satu event kalender
/// akademik lewat FK `kalender_id` (unique bersama `tanggal`). Baris ini
/// dihasilkan oleh endpoint `POST /admin/kalender-harian/generate` untuk
/// menjabarkan event multi-hari / berulang menjadi tanggal-tanggal konkret,
/// dan menyimpan override per hari: `status` dan `catatan`.
///
/// Karena itu ia BUKAN agenda yang berdiri sendiri, melainkan "kejadian harian"
/// dari sebuah event. Judul diambil dari relasi `kalender` yang di-eager-load
/// backend hanya pada mode AG-Grid (`startRow`/`endRow`).
class KalenderHarianEntity extends Equatable {
  final int id;
  final int? kalenderId;

  /// Format ternormalisasi "YYYY-MM-DD".
  final String tanggal;

  /// 0 = dibatalkan, 1 = aktif, 2 = selesai.
  final int status;

  final String? catatan;

  // ── Data dari relasi `kalender` (raw model, bukan Resource) ──────────────
  final String? eventJudul;
  final String? eventDeskripsi;
  final int? eventTipeId;
  final String? eventLokasi;

  const KalenderHarianEntity({
    required this.id,
    this.kalenderId,
    required this.tanggal,
    this.status = 1,
    this.catatan,
    this.eventJudul,
    this.eventDeskripsi,
    this.eventTipeId,
    this.eventLokasi,
  });

  DateTime? get tanggalDate => DateTime.tryParse(tanggal);

  bool get isDibatalkan => status == 0;
  bool get isSelesai => status == 2;

  /// Baris harian dianggap membawa informasi tambahan bila statusnya bukan
  /// "aktif" atau punya catatan. Baris tanpa keduanya hanyalah duplikat dari
  /// event induknya.
  bool get punyaInfoTambahan =>
      status != 1 || (catatan != null && catatan!.trim().isNotEmpty);

  @override
  List<Object?> get props => [id];
}
