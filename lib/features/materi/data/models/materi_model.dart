import '../../domain/entities/materi_entity.dart';

/// Model materi — parsing manual dari `MateriResource` backend.
///
/// Catatan: endpoint `GET /akademik/materi/guru-mapel/{id}` TIDAK melakukan
/// eager-load relasi `guruMapel`, sehingga key `guru_mapel` bisa tidak ada.
/// Semua field relasi karena itu null-safe.
class MateriModel {
  final int id;
  final int? guruMapelId;
  final String judul;
  final String? deskripsi;
  final String? fileMateri;
  final String? linkVideo;
  final int? status;
  final String? statusLabel;
  final int? guruId;
  final String? guruNama;
  final int? mapelId;
  final String? mapelKode;
  final String? mapelNama;
  final String? createdAt;
  final String? updatedAt;

  const MateriModel({
    required this.id,
    this.guruMapelId,
    required this.judul,
    this.deskripsi,
    this.fileMateri,
    this.linkVideo,
    this.status,
    this.statusLabel,
    this.guruId,
    this.guruNama,
    this.mapelId,
    this.mapelKode,
    this.mapelNama,
    this.createdAt,
    this.updatedAt,
  });

  factory MateriModel.fromJson(Map<String, dynamic> json) {
    final guruMapel = json['guru_mapel'] as Map<String, dynamic>?;
    final guru = guruMapel?['guru'] as Map<String, dynamic>?;
    final mapel = guruMapel?['mapel'] as Map<String, dynamic>?;

    return MateriModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      guruMapelId:
          (json['mst_guru_mapel_id'] as num?)?.toInt() ??
          (guruMapel?['id'] as num?)?.toInt(),
      judul: json['judul'] as String? ?? '(Tanpa judul)',
      deskripsi: json['deskripsi'] as String?,
      fileMateri: json['file_materi'] as String?,
      linkVideo: json['link_video'] as String?,
      status: (json['status'] as num?)?.toInt(),
      statusLabel: json['status_label'] as String?,
      guruId: (guru?['id'] as num?)?.toInt(),
      guruNama: guru?['nama'] as String?,
      mapelId: (mapel?['id'] as num?)?.toInt(),
      mapelKode: mapel?['kode'] as String?,
      mapelNama: mapel?['nama'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  MateriEntity toEntity() => MateriEntity(
    id: id,
    guruMapelId: guruMapelId,
    judul: judul,
    deskripsi: deskripsi,
    fileMateri: fileMateri,
    linkVideo: linkVideo,
    status: status,
    statusLabel: statusLabel,
    guruId: guruId,
    guruNama: guruNama,
    mapelId: mapelId,
    mapelKode: mapelKode,
    mapelNama: mapelNama,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}
