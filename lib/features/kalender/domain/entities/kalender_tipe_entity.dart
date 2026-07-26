import 'package:equatable/equatable.dart';

/// Tipe / kategori event kalender akademik.
///
/// Sumber: tabel `mst_kalender_akademik_tipe` (endpoint `/admin/kalender-tipe`).
/// Backend TIDAK menyimpan ikon — hanya `warna` (hex, mis. `#ef4444`) plus tiga
/// flag boolean yang kita pakai untuk memilih ikon di sisi mobile.
class KalenderTipeEntity extends Equatable {
  final int id;

  /// Kode unik, mis. `UJIAN`, `UTS`, `UAS`, `LIBUR`, `LIBUR_NASIONAL`,
  /// `KEGIATAN`, `PENTING`, `TES`.
  final String kode;

  /// Nama tampil, mis. "Ujian Tengah Semester".
  final String nama;

  /// Warna hex dari backend, mis. `#ef4444`. Bisa null.
  final String? warna;

  final String? keterangan;
  final bool isLibur;
  final bool isUjian;
  final bool isPenting;

  const KalenderTipeEntity({
    required this.id,
    required this.kode,
    required this.nama,
    this.warna,
    this.keterangan,
    this.isLibur = false,
    this.isUjian = false,
    this.isPenting = false,
  });

  @override
  List<Object?> get props => [id];
}
