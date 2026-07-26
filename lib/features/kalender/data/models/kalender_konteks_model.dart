import '../../domain/entities/kalender_konteks_entity.dart';
import 'kalender_field_parser.dart';

/// `TahunAjaranResource`: `id, kode, nama, tanggal_mulai, tanggal_selesai,
/// is_active, created_at, updated_at` (tanggal sudah `toDateString()`).
class TahunAjaranModel {
  final int id;
  final String kode;
  final String nama;
  final String? tanggalMulai;
  final String? tanggalSelesai;
  final bool isActive;

  const TahunAjaranModel({
    required this.id,
    required this.kode,
    required this.nama,
    this.tanggalMulai,
    this.tanggalSelesai,
    this.isActive = false,
  });

  factory TahunAjaranModel.fromJson(Map<String, dynamic> json) =>
      TahunAjaranModel(
        id: intAtau(json['id'], 0),
        kode: stringOpsional(json['kode']) ?? '',
        nama: stringOpsional(json['nama']) ?? '',
        tanggalMulai: normalisasiTanggal(json['tanggal_mulai']),
        tanggalSelesai: normalisasiTanggal(json['tanggal_selesai']),
        isActive: boolAtau(json['is_active'], false),
      );

  TahunAjaranEntity toEntity() => TahunAjaranEntity(
    id: id,
    kode: kode,
    nama: nama.isEmpty ? kode : nama,
    tanggalMulai: tanggalMulai,
    tanggalSelesai: tanggalSelesai,
    isActive: isActive,
  );
}

/// `SemesterResource`: `id, tahun_ajaran_id, tahun_ajaran, nama,
/// tanggal_mulai, tanggal_selesai, is_active, created_at, updated_at`.
/// Relasi `tahun_ajaran` ikut ter-load pada mode AG-Grid
/// (`MstSemester::query()->with('tahunAjaran')`).
class SemesterModel {
  final int id;
  final int? tahunAjaranId;
  final String nama;
  final String? tahunAjaranNama;
  final String? tanggalMulai;
  final String? tanggalSelesai;
  final bool isActive;

  const SemesterModel({
    required this.id,
    this.tahunAjaranId,
    required this.nama,
    this.tahunAjaranNama,
    this.tanggalMulai,
    this.tanggalSelesai,
    this.isActive = false,
  });

  factory SemesterModel.fromJson(Map<String, dynamic> json) {
    final ta = json['tahun_ajaran'];
    return SemesterModel(
      id: intAtau(json['id'], 0),
      tahunAjaranId: intOpsional(json['tahun_ajaran_id']),
      nama: stringOpsional(json['nama']) ?? '',
      tahunAjaranNama: ta is Map<String, dynamic>
          ? stringOpsional(ta['nama']) ?? stringOpsional(ta['kode'])
          : null,
      tanggalMulai: normalisasiTanggal(json['tanggal_mulai']),
      tanggalSelesai: normalisasiTanggal(json['tanggal_selesai']),
      isActive: boolAtau(json['is_active'], false),
    );
  }

  SemesterEntity toEntity() => SemesterEntity(
    id: id,
    tahunAjaranId: tahunAjaranId,
    nama: nama,
    tahunAjaranNama: tahunAjaranNama,
    tanggalMulai: tanggalMulai,
    tanggalSelesai: tanggalSelesai,
    isActive: isActive,
  );
}

/// `HariOperasionalResource`: `id, hari, is_active, created_at, updated_at`.
class HariOperasionalModel {
  final int id;
  final String hari;
  final bool isActive;

  const HariOperasionalModel({
    required this.id,
    required this.hari,
    this.isActive = true,
  });

  factory HariOperasionalModel.fromJson(Map<String, dynamic> json) =>
      HariOperasionalModel(
        id: intAtau(json['id'], 0),
        hari: stringOpsional(json['hari']) ?? '',
        isActive: boolAtau(json['is_active'], true),
      );

  HariOperasionalEntity toEntity() =>
      HariOperasionalEntity(id: id, hari: hari, isActive: isActive);
}
