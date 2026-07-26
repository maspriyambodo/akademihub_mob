import 'package:equatable/equatable.dart';

/// Satu baris peringkat kelas (`RankingResource`).
///
/// Field mengikuti `RankingResource` backend:
/// `id`, `trx_rapor_id`, `mst_kelas_id`, `mst_siswa_id`,
/// `siswa {id, nama, nis}`, `nis`, `kelas {id, nama_kelas}`,
/// `semester` (id mst_semester), `semester_nama`, `tahun_ajaran` (nama),
/// `rata_rata_nilai`, `peringkat`.
class RankingEntity extends Equatable {
  final int id;
  final int? raporId;
  final int? kelasId;
  final int? siswaId;
  final String? siswaNama;
  final String? nis;
  final String? kelasNama;

  /// Id mst_semester mentah (dipakai untuk prefill form generate/export).
  final int? semesterId;

  /// Nama semester (mis. "Ganjil").
  final String? semesterNama;

  /// Nama tahun ajaran (mis. "2025/2026").
  final String? tahunAjaran;

  final double? rataRata;
  final int? peringkat;

  const RankingEntity({
    required this.id,
    this.raporId,
    this.kelasId,
    this.siswaId,
    this.siswaNama,
    this.nis,
    this.kelasNama,
    this.semesterId,
    this.semesterNama,
    this.tahunAjaran,
    this.rataRata,
    this.peringkat,
  });

  @override
  List<Object?> get props => [id];
}
