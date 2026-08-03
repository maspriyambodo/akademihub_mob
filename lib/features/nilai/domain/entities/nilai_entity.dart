import 'package:equatable/equatable.dart';

/// Satu catatan nilai siswa (tabel `trx_nilai` + relasi ujian/mapel/siswa).
///
/// Sumber field mengikuti `NilaiResource` di backend:
/// `id`, `trx_ujian_id`, `mst_siswa_id`, `siswa{id,nama,nis}`,
/// `ujian{id,nama,jenis,jenis_kode,semester,semester_kode,tahun_ajaran,
/// tanggal,mapel{id,nama},kelas{id,nama_kelas}}`, `nilai`, `keterangan`.
class NilaiEntity extends Equatable {
  final int id;

  /// `trx_ujian_id`
  final int? ujianId;

  /// `mst_siswa_id`
  final int? siswaId;

  final String? siswaNama;
  final String? siswaNis;

  /// `ujian.nama` — nama ujian/penilaian
  final String? ujianNama;

  /// `ujian.jenis` — label jenis penilaian (mis. "UTS", "UAS", "Tugas")
  final String? jenisPenilaian;

  /// `ujian.jenis_kode` — kode mentah jenis penilaian
  final String? jenisKode;

  /// `ujian.semester` — nama semester (mis. "Ganjil")
  final String? semester;

  /// `ujian.semester_kode`
  final String? semesterKode;

  /// `ujian.tahun_ajaran`
  final String? tahunAjaran;

  /// `ujian.tanggal` dengan format "YYYY-MM-DD"
  final String? tanggalUjian;

  /// `ujian.mapel.id`
  final int? mapelId;

  /// `ujian.mapel.nama`
  final String? mapelNama;

  /// `ujian.kelas.nama_kelas`
  final String? kelasNama;

  /// Nilai numerik. Backend memakai cast `decimal:2` sehingga bisa terkirim
  /// sebagai string ("85.00") maupun angka.
  final double? nilai;

  final String? keterangan;

  const NilaiEntity({
    required this.id,
    this.ujianId,
    this.siswaId,
    this.siswaNama,
    this.siswaNis,
    this.ujianNama,
    this.jenisPenilaian,
    this.jenisKode,
    this.semester,
    this.semesterKode,
    this.tahunAjaran,
    this.tanggalUjian,
    this.mapelId,
    this.mapelNama,
    this.kelasNama,
    this.nilai,
    this.keterangan,
  });

  /// Label pengelompokan: utamakan nama mapel, jatuh ke nama ujian.
  String get mapelLabel {
    final mapel = mapelNama;
    if (mapel != null && mapel.trim().isNotEmpty) return mapel.trim();
    final ujian = ujianNama;
    if (ujian != null && ujian.trim().isNotEmpty) return ujian.trim();
    return 'Lainnya';
  }

  /// Judul baris: nama ujian, jatuh ke nama mapel.
  String get judul {
    final ujian = ujianNama;
    if (ujian != null && ujian.trim().isNotEmpty) return ujian.trim();
    final mapel = mapelNama;
    if (mapel != null && mapel.trim().isNotEmpty) return mapel.trim();
    return 'Penilaian';
  }

  /// Label semester penuh, mis. "Semester Genap Tahun Ajaran 2023/2024".
  String? get semesterLabel {
    final semRaw = (semester != null && semester!.trim().isNotEmpty)
        ? semester!.trim()
        : (semesterKode != null && semesterKode!.trim().isNotEmpty
              ? semesterKode!.trim()
              : null);
    final ta = (tahunAjaran != null && tahunAjaran!.trim().isNotEmpty)
        ? tahunAjaran!.trim()
        : null;

    if (semRaw == null && ta == null) return null;

    final sem = semRaw == null
        ? null
        : (semRaw.toLowerCase().startsWith('semester')
              ? semRaw
              : 'Semester $semRaw');

    if (sem != null && ta != null) {
      return '$sem Tahun Ajaran $ta';
    }
    if (sem != null) return sem;
    return 'Tahun Ajaran $ta';
  }

  /// Label ringkas untuk baris detail kartu (tanpa prefix berulang).
  String? get semesterDetailLabel {
    final full = semesterLabel;
    if (full == null) return null;
    return full.replaceFirst('Tahun Ajaran ', 'TA ');
  }

  DateTime? get tanggalUjianDate =>
      tanggalUjian == null ? null : DateTime.tryParse(tanggalUjian!);

  @override
  List<Object?> get props => [id];
}
