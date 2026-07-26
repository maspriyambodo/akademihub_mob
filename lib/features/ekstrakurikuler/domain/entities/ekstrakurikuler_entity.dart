import 'package:equatable/equatable.dart';

/// Entity ekstrakurikuler (tabel `mst_ekstrakurikuler`).
///
/// Backend TIDAK memakai API Resource untuk endpoint ekstrakurikuler, jadi JSON
/// yang diterima adalah serialisasi model Eloquent apa adanya:
/// `id`, `kode`, `nama`, `deskripsi`, `pembina_guru_id`, `hari`, `jam_mulai`,
/// `jam_selesai`, `lokasi`, `status`, `created_at`, `updated_at`, `deleted_at`.
///
/// Relasi `pembina` (mst_guru) hanya ikut ter-load pada endpoint index dan
/// show — endpoint `/aktif` dan `/pembina/{id}` tidak melakukan eager load.
class EkstrakurikulerEntity extends Equatable {
  final int id;
  final String? kode;
  final String nama;
  final String? deskripsi;

  final int? pembinaGuruId;

  /// Nama guru pembina, hanya terisi bila relasi `pembina` di-load backend.
  final String? pembinaNama;
  final String? pembinaNip;

  /// Hari kegiatan, contoh: `Senin` (kolom bebas, maks 20 karakter).
  final String? hari;

  /// Jam mulai/selesai sudah dinormalisasi ke format `HH:mm`.
  final String? jamMulai;
  final String? jamSelesai;

  final String? lokasi;

  /// `aktif` atau `nonaktif`.
  final String status;

  const EkstrakurikulerEntity({
    required this.id,
    this.kode,
    required this.nama,
    this.deskripsi,
    this.pembinaGuruId,
    this.pembinaNama,
    this.pembinaNip,
    this.hari,
    this.jamMulai,
    this.jamSelesai,
    this.lokasi,
    this.status = 'aktif',
  });

  bool get isAktif => status.toLowerCase() == 'aktif';

  String get statusLabel => isAktif ? 'Aktif' : 'Nonaktif';

  /// Label rentang jam, mis. `15:00 - 17:00`. Null bila jam tidak diisi.
  String? get jamLabel {
    final mulai = jamMulai;
    final selesai = jamSelesai;
    if (mulai == null && selesai == null) return null;
    if (mulai != null && selesai != null) return '$mulai - $selesai';
    return mulai ?? selesai;
  }

  /// Gabungan hari + jam, meniru accessor `getJadwalAttribute()` di backend
  /// (accessor tersebut tidak di-`$appends`, jadi tidak ikut dikirim JSON).
  String get jadwalLabel {
    final h = (hari == null || hari!.trim().isEmpty) ? null : hari!.trim();
    final j = jamLabel;
    if (h == null && j == null) return 'Jadwal belum diatur';
    if (h == null) return j!;
    if (j == null) return h;
    return '$h, $j';
  }

  bool get hasPembina => pembinaNama != null && pembinaNama!.trim().isNotEmpty;

  @override
  List<Object?> get props => [id];
}
