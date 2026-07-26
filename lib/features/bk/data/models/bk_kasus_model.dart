import '../../domain/entities/bk_kasus_entity.dart';

/// Model kasus BK — field diverifikasi dari `BkKasusResource` backend:
/// `id`, `siswa{id,nama,nis}`, `guru{id,nama}`, `jenis{id,kode,nama}`,
/// `tanggal`, `keterangan`, `status` (label), `created_at`, `updated_at`.
///
/// `tanggal`/`keterangan` di resource saat ini selalu null (resource membaca
/// atribut yang tidak ada; kolom aslinya `tanggal_mulai`/`deskripsi_masalah`),
/// jadi parser juga membaca nama kolom mentah sebagai cadangan.
class BkKasusModel {
  final int id;
  final int? siswaId;
  final String? siswaNama;
  final String? siswaNis;
  final int? guruId;
  final String? guruNama;
  final int? jenisId;
  final String? jenisKode;
  final String? jenisNama;
  final String? judul;
  final String? tanggal;
  final String? keterangan;
  final String? status;
  final String? createdAt;

  const BkKasusModel({
    required this.id,
    this.siswaId,
    this.siswaNama,
    this.siswaNis,
    this.guruId,
    this.guruNama,
    this.jenisId,
    this.jenisKode,
    this.jenisNama,
    this.judul,
    this.tanggal,
    this.keterangan,
    this.status,
    this.createdAt,
  });

  factory BkKasusModel.fromJson(Map<String, dynamic> json) {
    final siswa = json['siswa'] is Map<String, dynamic>
        ? json['siswa'] as Map<String, dynamic>
        : null;
    final guru = json['guru'] is Map<String, dynamic>
        ? json['guru'] as Map<String, dynamic>
        : null;
    final jenis = json['jenis'] is Map<String, dynamic>
        ? json['jenis'] as Map<String, dynamic>
        : null;

    return BkKasusModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      siswaId:
          (siswa?['id'] as num?)?.toInt() ??
          (json['mst_siswa_id'] as num?)?.toInt(),
      siswaNama: siswa?['nama'] as String?,
      siswaNis: siswa?['nis']?.toString(),
      guruId:
          (guru?['id'] as num?)?.toInt() ??
          (json['mst_guru_id'] as num?)?.toInt(),
      guruNama: guru?['nama'] as String?,
      jenisId:
          (jenis?['id'] as num?)?.toInt() ??
          (json['mst_bk_jenis_id'] as num?)?.toInt(),
      jenisKode: jenis?['kode']?.toString(),
      jenisNama: jenis?['nama'] as String?,
      judul: json['judul_kasus'] as String?,
      tanggal:
          json['tanggal'] as String? ?? json['tanggal_mulai']?.toString(),
      keterangan:
          json['keterangan'] as String? ?? json['deskripsi_masalah'] as String?,
      status: json['status']?.toString(),
      createdAt: json['created_at'] as String?,
    );
  }

  BkKasusEntity toEntity() => BkKasusEntity(
    id: id,
    siswaId: siswaId,
    siswaNama: siswaNama,
    siswaNis: siswaNis,
    guruId: guruId,
    guruNama: guruNama,
    jenisId: jenisId,
    jenisKode: jenisKode,
    jenisNama: jenisNama,
    judul: judul,
    tanggal: tanggal,
    keterangan: keterangan,
    status: status,
    createdAt: createdAt,
  );
}
