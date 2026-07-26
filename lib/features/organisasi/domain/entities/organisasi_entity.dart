import 'package:equatable/equatable.dart';

/// Entity organisasi sekolah (tabel `mst_organisasi`), mis. OSIS, MPK, Pramuka.
///
/// Endpoint index (`GET /organisasi` jalur AG-Grid) memakai `OrganisasiResource`
/// dengan field: `id`, `kode`, `nama`, `deskripsi`, `pembina_guru_id`,
/// `pembina {id, nama}`, `periode_mulai`, `periode_selesai`, `status`.
/// Endpoint `/aktif` dan `/{id}` mengirim serialisasi model Eloquent apa adanya
/// dengan nama field yang sama (relasi `pembina` = model `mst_guru` penuh).
class OrganisasiEntity extends Equatable {
  final int id;
  final String? kode;
  final String nama;
  final String? deskripsi;

  final int? pembinaGuruId;

  /// Nama guru pembina — hanya terisi bila relasi `pembina` di-load backend.
  final String? pembinaNama;
  final String? pembinaNip;

  /// Tahun mulai periode kepengurusan, mis. `2024`.
  final int? periodeMulai;

  /// Tahun selesai periode (nullable — organisasi bisa tanpa batas periode).
  final int? periodeSelesai;

  /// `aktif` atau `nonaktif` (CHECK constraint di DB).
  final String status;

  const OrganisasiEntity({
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

  bool get isAktif => status.toLowerCase() == 'aktif';

  String get statusLabel => isAktif ? 'Aktif' : 'Nonaktif';

  bool get hasPembina => pembinaNama != null && pembinaNama!.trim().isNotEmpty;

  /// Label periode, meniru accessor `getPeriodeAttribute()` backend
  /// (accessor tersebut tidak di-`$appends`, jadi tidak ikut JSON):
  /// `2024 - 2025`, `2024`, atau null bila tidak diisi.
  String? get periodeLabel {
    final mulai = periodeMulai;
    if (mulai == null) return null;
    final selesai = periodeSelesai;
    if (selesai == null || selesai == mulai) return '$mulai';
    return '$mulai - $selesai';
  }

  @override
  List<Object?> get props => [id];
}
