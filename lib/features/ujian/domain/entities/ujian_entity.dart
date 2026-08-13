import 'package:equatable/equatable.dart';

/// Satu ujian pada sebuah kelas (`UjianResource`).
///
/// Field mengikuti `UjianResource` backend:
/// `id`, `nama`, `jenis` (label dari sys_reference), `jenis_kode`,
/// `mapel {id, kode, nama}`, `kelas {id, nama_kelas}` (hanya bila relasi
/// dimuat), `tanggal` (Y-m-d), `semester` (nama), `semester_kode`,
/// `tahun_ajaran` (nama), `keterangan`.
class UjianEntity extends Equatable {
  final int id;
  final String nama;

  /// Label jenis ujian dari sys_reference (mis. "UTS", "UAS"), bisa null.
  final String? jenisLabel;
  final String? jenisKode;

  final int? mapelId;
  final String? mapelNama;
  final String? mapelKode;

  /// Relasi kelas TIDAK dimuat pada endpoint `by-kelas` (whenLoaded),
  /// jadi keduanya bisa null.
  final int? kelasId;
  final String? kelasNama;

  /// Tanggal ujian format `Y-m-d`.
  final String? tanggal;

  /// Nama semester dari mst_semester (mis. "Ganjil 2025/2026").
  final String? semesterNama;

  /// Id mst_semester dalam bentuk string (field `semester_kode`).
  final String? semesterKode;

  final String? tahunAjaran;
  final String? keterangan;

  const UjianEntity({
    required this.id,
    required this.nama,
    this.jenisLabel,
    this.jenisKode,
    this.mapelId,
    this.mapelNama,
    this.mapelKode,
    this.kelasId,
    this.kelasNama,
    this.tanggal,
    this.semesterNama,
    this.semesterKode,
    this.tahunAjaran,
    this.keterangan,
  });

  DateTime? get tanggalDate =>
      tanggal == null ? null : DateTime.tryParse(tanggal!);

  /// Id mst_semester sebagai int (untuk prefill form generate ranking).
  int? get semesterId =>
      semesterKode == null ? null : int.tryParse(semesterKode!);

  @override
  List<Object?> get props => [id];
}
