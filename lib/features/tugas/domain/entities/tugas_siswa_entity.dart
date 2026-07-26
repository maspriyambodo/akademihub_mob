import 'package:equatable/equatable.dart';

/// Entity untuk pengumpulan tugas oleh siswa (tabel `trx_tugas_siswa`).
class TugasSiswaEntity extends Equatable {
  final int id;
  final int? tugasId;
  final int? siswaId;

  /// Jawaban teks siswa (`jawaban`)
  final String? jawaban;

  /// URL / path file jawaban siswa (`file_jawaban`)
  final String? fileJawaban;

  /// ISO8601 waktu pengumpulan (`waktu_kumpul`)
  final String? waktuKumpul;

  /// Nilai 0..100. Backend selalu mengirim angka (0 bila belum dinilai).
  final double? nilai;

  final String? catatanGuru;

  /// 0 = Belum, 1 = Tepat Waktu, 2 = Terlambat
  final int status;
  final String? statusLabel;

  // ── Relasi siswa ───────────────────────────────────────────────────────────
  final String? siswaNama;
  final String? siswaNis;

  // ── Relasi tugas (bila di-load backend) ────────────────────────────────────
  final String? tugasJudul;
  final String? tugasDeskripsi;
  final String? tugasTenggatWaktu;
  final int? tugasKelasId;
  final String? tugasKelasNama;
  final String? tugasMapelNama;
  final String? tugasGuruNama;

  const TugasSiswaEntity({
    required this.id,
    this.tugasId,
    this.siswaId,
    this.jawaban,
    this.fileJawaban,
    this.waktuKumpul,
    this.nilai,
    this.catatanGuru,
    this.status = 0,
    this.statusLabel,
    this.siswaNama,
    this.siswaNis,
    this.tugasJudul,
    this.tugasDeskripsi,
    this.tugasTenggatWaktu,
    this.tugasKelasId,
    this.tugasKelasNama,
    this.tugasMapelNama,
    this.tugasGuruNama,
  });

  DateTime? get waktuKumpulDate =>
      waktuKumpul == null ? null : DateTime.tryParse(waktuKumpul!);

  /// Sudah mengumpulkan bila status != 0 atau ada waktu_kumpul.
  bool get sudahDikumpulkan => status != 0 || waktuKumpulDate != null;

  /// Terlambat mengumpulkan (status 2 dari backend).
  bool get isTerlambat => status == 2;

  /// Backend tidak mengekspos `waktu_dinilai`, sehingga "sudah dinilai"
  /// disimpulkan dari nilai > 0 (nilai default saat dibuat adalah 0).
  bool get sudahDinilai => (nilai ?? 0) > 0;

  String get nilaiLabel {
    final n = nilai;
    if (n == null) return '-';
    if (n == n.roundToDouble()) return n.toInt().toString();
    return n.toStringAsFixed(2);
  }

  @override
  List<Object?> get props => [id];
}
