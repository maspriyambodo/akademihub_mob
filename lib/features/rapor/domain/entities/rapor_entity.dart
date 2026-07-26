import 'package:equatable/equatable.dart';
import 'rapor_mapel_entity.dart';

/// Satu rapor (satu siswa untuk satu semester).
///
/// Backend: `TrxRapor` + `RaporResource`.
/// Endpoint: `GET /akademik/rapor`, `GET /akademik/rapor/{id}`,
/// `GET /akademik/rapor/siswa/{siswaId}`.
class RaporEntity extends Equatable {
  final int id;

  /// `mst_siswa_id`
  final int? siswaId;

  /// `siswa.nama` — hanya ada bila relasi siswa di-load (index & by-siswa: ya).
  final String? siswaNama;

  /// `siswa.nis`
  final String? siswaNis;

  /// `kelas` — backend mengirim langsung string `nama_kelas`, bukan objek.
  final String? kelas;

  /// `semester` — nama semester dari `mst_semester.nama` (mis. "Ganjil").
  final String? semester;

  /// `semester_kode` — id semester yang dikirim sebagai string oleh backend.
  final String? semesterKode;

  /// `tahun_ajaran_id`
  final int? tahunAjaranId;

  /// `tahun_ajaran` — nama tahun ajaran (mis. "2024/2025").
  final String? tahunAjaran;

  /// `catatan_wali` — narasi / catatan wali kelas.
  final String? catatanWali;

  final double? totalNilai;
  final double? rataRata;

  // Rekap kehadiran (`kehadiran.*`)
  final int? sakit;
  final int? izin;
  final int? tanpaKeterangan;

  /// `ranking.peringkat` — hanya ter-load pada endpoint show (`/rapor/{id}`).
  final int? peringkat;

  /// `detail[]` — ikut terkirim pada endpoint by-siswa dan show.
  /// Pada endpoint index relasi ini tidak di-load → list kosong.
  final List<RaporMapelEntity> detail;

  const RaporEntity({
    required this.id,
    this.siswaId,
    this.siswaNama,
    this.siswaNis,
    this.kelas,
    this.semester,
    this.semesterKode,
    this.tahunAjaranId,
    this.tahunAjaran,
    this.catatanWali,
    this.totalNilai,
    this.rataRata,
    this.sakit,
    this.izin,
    this.tanpaKeterangan,
    this.peringkat,
    this.detail = const [],
  });

  bool get punyaKehadiran =>
      sakit != null || izin != null || tanpaKeterangan != null;

  /// Label periode untuk judul kartu, mis. "Semester Ganjil · 2024/2025".
  String get labelPeriode {
    final s = (semester != null && semester!.isNotEmpty)
        ? 'Semester $semester'
        : (semesterKode != null && semesterKode!.isNotEmpty
              ? 'Semester $semesterKode'
              : 'Semester -');
    if (tahunAjaran != null && tahunAjaran!.isNotEmpty) {
      return '$s · $tahunAjaran';
    }
    return s;
  }

  @override
  List<Object?> get props => [id];
}
