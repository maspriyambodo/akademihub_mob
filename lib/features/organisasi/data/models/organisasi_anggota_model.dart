import '../../domain/entities/organisasi_anggota_entity.dart';

/// Model anggota organisasi — parsing manual dari serialisasi Eloquent
/// `TrxOrganisasiAnggota` dengan relasi `jabatan` dan `siswa` ter-load
/// (bentuk yang dikirim `GET /organisasi/{id}` dan
/// `GET /organisasi/anggota/organisasi/{id}`).
///
/// PERHATIAN skema (sudah diverifikasi di migrasi backend):
/// - `status` = smallint 0/1/2, BUKAN string.
/// - Tanggal memakai kolom `tanggal_masuk`/`tanggal_keluar`.
///   (`OrganisasiAnggotaResource` di backend salah merujuk `tanggal_mulai`/
///   `tanggal_selesai` yang tidak ada — endpoint yang memakai resource itu
///   sengaja TIDAK dipakai di mobile.)
class OrganisasiAnggotaModel {
  final int id;
  final int? organisasiId;
  final int? siswaId;
  final String siswaNama;
  final String? siswaNis;
  final int? jabatanId;
  final String? jabatanNama;
  final int? jabatanUrutan;
  final int status;
  final DateTime? tanggalMasuk;
  final DateTime? tanggalKeluar;
  final String? keterangan;

  const OrganisasiAnggotaModel({
    required this.id,
    this.organisasiId,
    this.siswaId,
    required this.siswaNama,
    this.siswaNis,
    this.jabatanId,
    this.jabatanNama,
    this.jabatanUrutan,
    this.status = 1,
    this.tanggalMasuk,
    this.tanggalKeluar,
    this.keterangan,
  });

  factory OrganisasiAnggotaModel.fromJson(Map<String, dynamic> json) {
    final siswa = json['siswa'] as Map<String, dynamic>?;
    final jabatan = json['jabatan'] as Map<String, dynamic>?;

    return OrganisasiAnggotaModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      organisasiId: (json['organisasi_id'] as num?)?.toInt(),
      siswaId:
          (json['siswa_id'] as num?)?.toInt() ??
          (siswa?['id'] as num?)?.toInt(),
      siswaNama: siswa?['nama'] as String? ?? '(Tanpa nama)',
      siswaNis: siswa?['nis']?.toString(),
      jabatanId:
          (json['jabatan_id'] as num?)?.toInt() ??
          (jabatan?['id'] as num?)?.toInt(),
      jabatanNama: jabatan?['nama'] as String?,
      jabatanUrutan: (jabatan?['urutan'] as num?)?.toInt(),
      status: parseStatus(json['status']),
      tanggalMasuk: parseTanggal(json['tanggal_masuk']),
      tanggalKeluar: parseTanggal(json['tanggal_keluar']),
      keterangan: json['keterangan'] as String?,
    );
  }

  /// `status` di-cast `integer` di model backend, tapi tetap dijaga bila
  /// dikirim sebagai string angka.
  static int parseStatus(dynamic raw) {
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw) ?? 1;
    return 1;
  }

  /// Cast `date` Laravel diserialisasi ISO8601
  /// (`2024-07-01T00:00:00.000000Z`); tangani juga `yyyy-MM-dd` polos.
  static DateTime? parseTanggal(dynamic raw) {
    if (raw == null) return null;
    final text = raw.toString().trim();
    if (text.isEmpty) return null;
    return DateTime.tryParse(text);
  }

  OrganisasiAnggotaEntity toEntity() => OrganisasiAnggotaEntity(
    id: id,
    organisasiId: organisasiId,
    siswaId: siswaId,
    siswaNama: siswaNama,
    siswaNis: siswaNis,
    jabatanId: jabatanId,
    jabatanNama: jabatanNama,
    jabatanUrutan: jabatanUrutan,
    status: status,
    tanggalMasuk: tanggalMasuk,
    tanggalKeluar: tanggalKeluar,
    keterangan: keterangan,
  );
}
