import '../../domain/entities/organisasi_entity.dart';

/// Model organisasi — parsing manual.
///
/// Menangani dua bentuk payload dengan nama field yang sama:
/// - `OrganisasiResource` (jalur AG-Grid index): `pembina` = `{id, nama}`.
/// - Serialisasi Eloquent mentah (`/aktif`, `/{id}`): `pembina` = model
///   `mst_guru` penuh (`nama`, `nip`, dst.).
class OrganisasiModel {
  final int id;
  final String? kode;
  final String nama;
  final String? deskripsi;
  final int? pembinaGuruId;
  final String? pembinaNama;
  final String? pembinaNip;
  final int? periodeMulai;
  final int? periodeSelesai;
  final String status;

  const OrganisasiModel({
    required this.id,
    this.kode,
    required this.nama,
    this.deskripsi,
    this.pembinaGuruId,
    this.pembinaNama,
    this.pembinaNip,
    this.periodeMulai,
    this.periodeSelesai,
    this.status = 'aktif',
  });

  factory OrganisasiModel.fromJson(Map<String, dynamic> json) {
    final pembina = json['pembina'] as Map<String, dynamic>?;

    return OrganisasiModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      kode: json['kode'] as String?,
      nama: json['nama'] as String? ?? '(Tanpa nama)',
      deskripsi: json['deskripsi'] as String?,
      pembinaGuruId:
          (json['pembina_guru_id'] as num?)?.toInt() ??
          (pembina?['id'] as num?)?.toInt(),
      pembinaNama: pembina?['nama'] as String?,
      pembinaNip: pembina?['nip'] as String?,
      periodeMulai: (json['periode_mulai'] as num?)?.toInt(),
      periodeSelesai: (json['periode_selesai'] as num?)?.toInt(),
      status: json['status'] as String? ?? 'aktif',
    );
  }

  OrganisasiEntity toEntity() => OrganisasiEntity(
    id: id,
    kode: kode,
    nama: nama,
    deskripsi: deskripsi,
    pembinaGuruId: pembinaGuruId,
    pembinaNama: pembinaNama,
    pembinaNip: pembinaNip,
    periodeMulai: periodeMulai,
    periodeSelesai: periodeSelesai,
    status: status,
  );
}
