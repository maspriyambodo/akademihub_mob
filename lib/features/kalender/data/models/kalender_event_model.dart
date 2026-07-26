import '../../domain/entities/kalender_event_entity.dart';
import 'kalender_field_parser.dart';
import 'kalender_tipe_model.dart';

/// Mengikuti `KalenderAkademikResource`:
/// `id, semester_id, semester, tipe_id, tipe, created_by, judul, deskripsi,
///  tanggal_mulai, tanggal_selesai, waktu_mulai, waktu_selesai, status,
///  prioritas, lokasi, is_all_day, is_recurring, recurring_rule, metadata,
///  roles, kelas, jurusan, created_at, updated_at`.
///
/// `tipe` dan `semester` selalu ter-eager-load pada endpoint index
/// (`with(['tipe','semester'])` di AG-Grid mode, `with(['semester','tipe',...])`
/// di mode paginasi biasa).
class KalenderEventModel {
  final int id;
  final int? tipeId;
  final KalenderTipeModel? tipe;
  final int? semesterId;
  final String? semesterNama;
  final String? tahunAjaranNama;
  final String judul;
  final String? deskripsi;
  final String tanggalMulai;
  final String? tanggalSelesai;
  final String? waktuMulai;
  final String? waktuSelesai;
  final int status;
  final int prioritas;
  final String? lokasi;
  final bool isAllDay;
  final bool isRecurring;

  const KalenderEventModel({
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

  factory KalenderEventModel.fromJson(Map<String, dynamic> json) {
    final tipeRaw = json['tipe'];
    final semesterRaw = json['semester'];
    final tahunAjaranRaw = semesterRaw is Map<String, dynamic>
        ? semesterRaw['tahun_ajaran']
        : null;

    final mulai = normalisasiTanggal(json['tanggal_mulai']);
    var selesai = normalisasiTanggal(json['tanggal_selesai']);
    // Backend membolehkan tanggal_selesai == tanggal_mulai; anggap 1 hari.
    if (selesai != null && mulai != null && selesai == mulai) selesai = null;

    return KalenderEventModel(
      id: intAtau(json['id'], 0),
      tipeId: intOpsional(json['tipe_id']),
      tipe: tipeRaw is Map<String, dynamic>
          ? KalenderTipeModel.fromJson(tipeRaw)
          : null,
      semesterId: intOpsional(json['semester_id']),
      semesterNama: semesterRaw is Map<String, dynamic>
          ? stringOpsional(semesterRaw['nama'])
          : null,
      tahunAjaranNama: tahunAjaranRaw is Map<String, dynamic>
          ? stringOpsional(tahunAjaranRaw['nama'])
          : null,
      judul: stringOpsional(json['judul']) ?? 'Tanpa Judul',
      deskripsi: stringOpsional(json['deskripsi']),
      tanggalMulai: mulai ?? '',
      tanggalSelesai: selesai,
      waktuMulai: normalisasiWaktu(json['waktu_mulai']),
      waktuSelesai: normalisasiWaktu(json['waktu_selesai']),
      status: intAtau(json['status'], 1),
      prioritas: intAtau(json['prioritas'], 2),
      lokasi: stringOpsional(json['lokasi']),
      isAllDay: boolAtau(json['is_all_day'], false),
      isRecurring: boolAtau(json['is_recurring'], false),
    );
  }

  KalenderEventEntity toEntity() => KalenderEventEntity(
    id: id,
    tipeId: tipeId,
    tipe: tipe?.toEntity(),
    semesterId: semesterId,
    semesterNama: semesterNama,
    tahunAjaranNama: tahunAjaranNama,
    judul: judul,
    deskripsi: deskripsi,
    tanggalMulai: tanggalMulai,
    tanggalSelesai: tanggalSelesai,
    waktuMulai: waktuMulai,
    waktuSelesai: waktuSelesai,
    status: status,
    prioritas: prioritas,
    lokasi: lokasi,
    isAllDay: isAllDay,
    isRecurring: isRecurring,
  );
}
