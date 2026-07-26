import '../../domain/entities/tugas_entity.dart';

/// Model tugas — parsing manual dari `TugasResource` backend.
class TugasModel {
  final int id;
  final int? guruMapelId;
  final int? kelasId;
  final String judul;
  final String? deskripsi;
  final String? fileLampiran;
  final String? tenggatWaktu;
  final int? status;
  final String? statusLabel;
  final int? guruId;
  final String? guruNama;
  final String? mapelKode;
  final String? mapelNama;
  final String? kelasNama;
  final String? kelasLevel;

  const TugasModel({
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

  factory TugasModel.fromJson(Map<String, dynamic> json) {
    final guruMapel = json['guru_mapel'] as Map<String, dynamic>?;
    final guru = guruMapel?['guru'] as Map<String, dynamic>?;
    final mapel = guruMapel?['mapel'] as Map<String, dynamic>?;
    final kelas = json['kelas'] as Map<String, dynamic>?;

    return TugasModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      guruMapelId:
          (json['mst_guru_mapel_id'] as num?)?.toInt() ??
          (guruMapel?['id'] as num?)?.toInt(),
      kelasId:
          (json['mst_kelas_id'] as num?)?.toInt() ??
          (kelas?['id'] as num?)?.toInt(),
      judul: json['judul'] as String? ?? '(Tanpa judul)',
      deskripsi: json['deskripsi'] as String?,
      fileLampiran: json['file_lampiran'] as String?,
      tenggatWaktu: json['tenggat_waktu'] as String?,
      status: (json['status'] as num?)?.toInt(),
      statusLabel: json['status_label'] as String?,
      guruId: (guru?['id'] as num?)?.toInt(),
      guruNama: guru?['nama'] as String?,
      mapelKode: mapel?['kode'] as String?,
      mapelNama: mapel?['nama'] as String?,
      kelasNama: kelas?['nama'] as String?,
      kelasLevel: kelas?['level']?.toString(),
    );
  }

  TugasEntity toEntity() => TugasEntity(
    id: id,
    guruMapelId: guruMapelId,
    kelasId: kelasId,
    judul: judul,
    deskripsi: deskripsi,
    fileLampiran: fileLampiran,
    tenggatWaktu: tenggatWaktu,
    status: status,
    statusLabel: statusLabel,
    guruId: guruId,
    guruNama: guruNama,
    mapelKode: mapelKode,
    mapelNama: mapelNama,
    kelasNama: kelasNama,
    kelasLevel: kelasLevel,
  );
}
