import '../../domain/entities/log_akses_materi_entity.dart';

/// Model log akses materi — parsing manual dari `LogAksesMateriResource`.
class LogAksesMateriModel {
  final int id;
  final int? materiId;
  final int? siswaId;
  final int? kelasId;
  final String? waktuAkses;
  final int durasiDetik;
  final String? durasiLabel;
  final int? status;
  final int? progressPersen;
  final String? materiJudul;
  final String? siswaNama;
  final String? siswaNis;

  const LogAksesMateriModel({
    required this.id,
    this.materiId,
    this.siswaId,
    this.kelasId,
    this.waktuAkses,
    this.durasiDetik = 0,
    this.durasiLabel,
    this.status,
    this.progressPersen,
    this.materiJudul,
    this.siswaNama,
    this.siswaNis,
  });

  factory LogAksesMateriModel.fromJson(Map<String, dynamic> json) {
    final materi = json['materi'] as Map<String, dynamic>?;
    final siswa = json['siswa'] as Map<String, dynamic>?;

    return LogAksesMateriModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      materiId: (json['materi_id'] as num?)?.toInt(),
      siswaId: (json['siswa_id'] as num?)?.toInt(),
      kelasId: (json['kelas_id'] as num?)?.toInt(),
      waktuAkses: json['waktu_akses'] as String?,
      durasiDetik: (json['durasi_detik'] as num?)?.toInt() ?? 0,
      durasiLabel: json['durasi_label'] as String?,
      status: (json['status'] as num?)?.toInt(),
      progressPersen: (json['progress_persen'] as num?)?.toInt(),
      materiJudul: materi?['judul'] as String?,
      siswaNama: siswa?['nama'] as String?,
      siswaNis: siswa?['nis']?.toString(),
    );
  }

  LogAksesMateriEntity toEntity() => LogAksesMateriEntity(
    id: id,
    materiId: materiId,
    siswaId: siswaId,
    kelasId: kelasId,
    waktuAkses: waktuAkses,
    durasiDetik: durasiDetik,
    durasiLabel: durasiLabel,
    status: status,
    progressPersen: progressPersen,
    materiJudul: materiJudul,
    siswaNama: siswaNama,
    siswaNis: siswaNis,
  );
}

/// Model agregat `GET /akademik/log-akses-materi/popular`.
///
/// Endpoint ini mengembalikan koleksi Eloquent mentah (bukan Resource), jadi
/// bentuknya: `{ materi_id, total_akses, total_durasi, materi: {...} }`.
/// `total_akses`/`total_durasi` bisa datang sebagai string dari driver DB.
class MateriPopulerModel {
  final int materiId;
  final String? judul;
  final int totalAkses;
  final int totalDurasiDetik;

  const MateriPopulerModel({
    required this.materiId,
    this.judul,
    this.totalAkses = 0,
    this.totalDurasiDetik = 0,
  });

  static int _toInt(dynamic value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  factory MateriPopulerModel.fromJson(Map<String, dynamic> json) {
    final materi = json['materi'] as Map<String, dynamic>?;
    return MateriPopulerModel(
      materiId:
          (json['materi_id'] as num?)?.toInt() ??
          (materi?['id'] as num?)?.toInt() ??
          0,
      judul: materi?['judul'] as String?,
      totalAkses: _toInt(json['total_akses']),
      totalDurasiDetik: _toInt(json['total_durasi']),
    );
  }

  MateriPopulerEntity toEntity() => MateriPopulerEntity(
    materiId: materiId,
    judul: judul,
    totalAkses: totalAkses,
    totalDurasiDetik: totalDurasiDetik,
  );
}
