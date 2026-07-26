import 'package:equatable/equatable.dart';

/// Entity pendaftaran siswa ke ekstrakurikuler (tabel
/// `trx_ekstrakurikuler_siswa`), mengikuti `EkstrakurikulerSiswaResource`.
///
/// Field resource: `id`, `ekstrakurikuler_id`, `siswa_id`, `tanggal_daftar`
/// (Y-m-d), `status` (`aktif`|`keluar`), `ekstrakurikuler` (hanya id/nama/
/// deskripsi), `siswa` (id/nama/nis/nisn), `created_at`, `updated_at`,
/// `deleted_at`.
class PendaftaranEkskulEntity extends Equatable {
  final int id;
  final int? ekstrakurikulerId;
  final int? siswaId;

  /// Tanggal daftar mentah berformat `yyyy-MM-dd`.
  final String? tanggalDaftar;

  /// `aktif` atau `keluar`.
  final String status;

  // ── Relasi ekstrakurikuler (hanya id, nama, deskripsi dari resource) ───────
  final String? ekstrakurikulerNama;
  final String? ekstrakurikulerDeskripsi;

  // ── Relasi siswa ──────────────────────────────────────────────────────────
  final String? siswaNama;
  final String? siswaNis;
  final String? siswaNisn;

  const PendaftaranEkskulEntity({
    required this.id,
    this.ekstrakurikulerId,
    this.siswaId,
    this.tanggalDaftar,
    this.status = 'aktif',
    this.ekstrakurikulerNama,
    this.ekstrakurikulerDeskripsi,
    this.siswaNama,
    this.siswaNis,
    this.siswaNisn,
  });

  bool get isAktif => status.toLowerCase() == 'aktif';

  String get statusLabel => isAktif ? 'Aktif' : 'Keluar';

  DateTime? get tanggalDaftarDate =>
      tanggalDaftar == null ? null : DateTime.tryParse(tanggalDaftar!);

  String get namaTampil =>
      (ekstrakurikulerNama != null && ekstrakurikulerNama!.trim().isNotEmpty)
      ? ekstrakurikulerNama!
      : 'Ekstrakurikuler #${ekstrakurikulerId ?? '-'}';

  @override
  List<Object?> get props => [id];
}
