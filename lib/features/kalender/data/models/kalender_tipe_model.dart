import '../../domain/entities/kalender_tipe_entity.dart';
import 'kalender_field_parser.dart';

/// Mengikuti `KalenderAkademikTipeResource`:
/// `id, kode, nama, warna, keterangan, is_libur, is_ujian, is_penting`.
class KalenderTipeModel {
  final int id;
  final String kode;
  final String nama;
  final String? warna;
  final String? keterangan;
  final bool isLibur;
  final bool isUjian;
  final bool isPenting;

  const KalenderTipeModel({
    required this.id,
    required this.kode,
    required this.nama,
    this.warna,
    this.keterangan,
    this.isLibur = false,
    this.isUjian = false,
    this.isPenting = false,
  });

  factory KalenderTipeModel.fromJson(Map<String, dynamic> json) {
    return KalenderTipeModel(
      id: intAtau(json['id'], 0),
      kode: stringOpsional(json['kode']) ?? '',
      nama: stringOpsional(json['nama']) ?? 'Tanpa Kategori',
      warna: stringOpsional(json['warna']),
      keterangan: stringOpsional(json['keterangan']),
      isLibur: boolAtau(json['is_libur'], false),
      isUjian: boolAtau(json['is_ujian'], false),
      isPenting: boolAtau(json['is_penting'], false),
    );
  }

  KalenderTipeEntity toEntity() => KalenderTipeEntity(
    id: id,
    kode: kode,
    // Beberapa data seed punya spasi di depan (mis. " Kegiatan Sekolah").
    nama: nama.trim(),
    warna: warna,
    keterangan: keterangan,
    isLibur: isLibur,
    isUjian: isUjian,
    isPenting: isPenting,
  );
}
