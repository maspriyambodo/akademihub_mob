import '../../domain/entities/kalender_harian_entity.dart';
import 'kalender_field_parser.dart';

/// Mengikuti `KalenderHarianResource`:
/// `id, kalender_id, tanggal, status, catatan, metadata, kalender,
///  created_at, updated_at`.
///
/// Perhatian: `kalender` di-serialize sebagai MODEL Eloquent mentah
/// (`$this->whenLoaded('kalender')`), BUKAN `KalenderAkademikResource`.
/// Jadi isinya kolom tabel apa adanya (`judul`, `deskripsi`, `lokasi`,
/// `tipe_id`, …) dan TIDAK ada objek `tipe` bersarang — tipe harus dicocokkan
/// sendiri lewat `tipe_id`. Relasi ini hanya ter-eager-load pada mode AG-Grid.
class KalenderHarianModel {
  final int id;
  final int? kalenderId;
  final String tanggal;
  final int status;
  final String? catatan;
  final String? eventJudul;
  final String? eventDeskripsi;
  final int? eventTipeId;
  final String? eventLokasi;

  const KalenderHarianModel({
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

  factory KalenderHarianModel.fromJson(Map<String, dynamic> json) {
    final kalenderRaw = json['kalender'];
    final kalender = kalenderRaw is Map<String, dynamic> ? kalenderRaw : null;

    return KalenderHarianModel(
      id: intAtau(json['id'], 0),
      kalenderId: intOpsional(json['kalender_id']),
      tanggal: normalisasiTanggal(json['tanggal']) ?? '',
      status: intAtau(json['status'], 1),
      catatan: stringOpsional(json['catatan']),
      eventJudul: kalender == null ? null : stringOpsional(kalender['judul']),
      eventDeskripsi: kalender == null
          ? null
          : stringOpsional(kalender['deskripsi']),
      eventTipeId: kalender == null ? null : intOpsional(kalender['tipe_id']),
      eventLokasi: kalender == null ? null : stringOpsional(kalender['lokasi']),
    );
  }

  KalenderHarianEntity toEntity() => KalenderHarianEntity(
    id: id,
    kalenderId: kalenderId,
    tanggal: tanggal,
    status: status,
    catatan: catatan,
    eventJudul: eventJudul,
    eventDeskripsi: eventDeskripsi,
    eventTipeId: eventTipeId,
    eventLokasi: eventLokasi,
  );
}
