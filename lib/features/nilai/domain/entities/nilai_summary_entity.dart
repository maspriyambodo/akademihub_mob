import 'package:equatable/equatable.dart';

/// Ringkasan nilai yang ditampilkan di bagian atas halaman.
class NilaiSummaryEntity extends Equatable {
  /// Rata-rata keseluruhan. Diambil dari endpoint
  /// `/akademik/nilai/siswa/{id}/rata-rata` bila tersedia, kalau tidak
  /// dihitung dari daftar nilai yang dimuat.
  final double? rataRata;

  /// Jumlah mata pelajaran unik pada daftar nilai.
  final int jumlahMapel;

  final double? tertinggi;
  final double? terendah;

  /// Jumlah catatan nilai.
  final int total;

  const NilaiSummaryEntity({
    this.rataRata,
    this.jumlahMapel = 0,
    this.tertinggi,
    this.terendah,
    this.total = 0,
  });

  static const NilaiSummaryEntity empty = NilaiSummaryEntity();

  @override
  List<Object?> get props => [
    rataRata,
    jumlahMapel,
    tertinggi,
    terendah,
    total,
  ];
}
