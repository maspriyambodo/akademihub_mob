import 'package:equatable/equatable.dart';
import 'rapor_mapel_entity.dart';

/// Hasil endpoint `GET /akademik/rapor/{id}/detail`.
///
/// PENTING: response endpoint ini dibentuk manual di
/// `RaporService::getRaporDetail()` — BUKAN `RaporResource`. Field yang tersedia
/// hanya: id, mst_siswa_id, siswa{id,nis,nama}, semester, tahun_ajaran,
/// catatan_wali, kehadiran{sakit,izin,tanpa_keterangan}, detail[].
///
/// Tidak ada `kelas`, `rata_rata`, `total_nilai`, maupun `ranking` di sini —
/// nilai-nilai itu diambil dari data list (RaporEntity) saat menampilkan header.
class RaporDetailEntity extends Equatable {
  final int id;
  final int? siswaId;
  final String? siswaNama;
  final String? siswaNis;

  final String? semester;
  final String? tahunAjaran;

  /// Narasi / catatan wali kelas.
  final String? catatanWali;

  final int? sakit;
  final int? izin;
  final int? tanpaKeterangan;

  /// Rincian nilai per mata pelajaran.
  final List<RaporMapelEntity> mapel;

  const RaporDetailEntity({
    required this.id,
    this.siswaId,
    this.siswaNama,
    this.siswaNis,
    this.semester,
    this.tahunAjaran,
    this.catatanWali,
    this.sakit,
    this.izin,
    this.tanpaKeterangan,
    this.mapel = const [],
  });

  bool get punyaKehadiran =>
      sakit != null || izin != null || tanpaKeterangan != null;

  bool get punyaCatatan => catatanWali != null && catatanWali!.trim().isNotEmpty;

  /// Rata-rata dihitung dari rincian mapel (endpoint detail tidak mengirimnya).
  double? get rataRataHitung {
    final nilai = mapel
        .map((m) => m.nilaiUtama)
        .whereType<double>()
        .toList(growable: false);
    if (nilai.isEmpty) return null;
    return nilai.reduce((a, b) => a + b) / nilai.length;
  }

  @override
  List<Object?> get props => [id];
}
