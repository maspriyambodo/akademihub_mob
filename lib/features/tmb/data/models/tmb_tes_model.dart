import '../../domain/entities/tmb_tes_entity.dart';

/// Model JSON mentah `trx_tes_minat_bakat` (controller tidak memakai Resource,
/// field persis kolom database + relasi Eloquent snake_case).
class TmbTesModel {
  final int id;
  final String namaTes;
  final String? deskripsi;
  final int tipeTes;
  final int status;
  final String? waktuMulai;
  final String? waktuSelesai;
  final int? durasiMenit;
  final int? targetPeserta;
  final String? semesterNama;

  const TmbTesModel({
    required this.id,
    required this.namaTes,
    this.deskripsi,
    this.tipeTes = 1,
    this.status = 0,
    this.waktuMulai,
    this.waktuSelesai,
    this.durasiMenit,
    this.targetPeserta,
    this.semesterNama,
  });

  factory TmbTesModel.fromJson(Map<String, dynamic> json) {
    final semester = json['semester'];
    return TmbTesModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      namaTes: json['nama_tes'] as String? ?? '-',
      deskripsi: json['deskripsi'] as String?,
      tipeTes: (json['tipe_tes'] as num?)?.toInt() ?? 1,
      status: (json['status'] as num?)?.toInt() ?? 0,
      waktuMulai: json['waktu_mulai'] as String?,
      waktuSelesai: json['waktu_selesai'] as String?,
      durasiMenit: (json['durasi_menit'] as num?)?.toInt(),
      targetPeserta: (json['target_peserta'] as num?)?.toInt(),
      semesterNama: semester is Map ? semester['nama'] as String? : null,
    );
  }

  TmbTesEntity toEntity() => TmbTesEntity(
    id: id,
    namaTes: namaTes,
    deskripsi: deskripsi,
    tipeTes: tipeTes,
    status: status,
    waktuMulai: waktuMulai,
    waktuSelesai: waktuSelesai,
    durasiMenit: durasiMenit,
    targetPeserta: targetPeserta,
    semesterNama: semesterNama,
  );
}
