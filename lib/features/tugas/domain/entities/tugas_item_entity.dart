import 'package:equatable/equatable.dart';
import 'tugas_entity.dart';
import 'tugas_siswa_entity.dart';

/// Status pengumpulan gabungan (tugas + data pengumpulan milik siswa).
enum StatusPengumpulan { belum, dikumpulkan, dinilai }

extension StatusPengumpulanLabel on StatusPengumpulan {
  String get label => switch (this) {
    StatusPengumpulan.belum => 'Belum dikumpulkan',
    StatusPengumpulan.dikumpulkan => 'Sudah dikumpulkan',
    StatusPengumpulan.dinilai => 'Sudah dinilai',
  };
}

/// Gabungan satu tugas dengan pengumpulan milik siswa (bila ada).
class TugasItemEntity extends Equatable {
  final TugasEntity tugas;
  final TugasSiswaEntity? pengumpulan;

  const TugasItemEntity({required this.tugas, this.pengumpulan});

  StatusPengumpulan get statusPengumpulan {
    final p = pengumpulan;
    if (p == null) return StatusPengumpulan.belum;
    if (p.sudahDinilai) return StatusPengumpulan.dinilai;
    if (p.sudahDikumpulkan) return StatusPengumpulan.dikumpulkan;
    return StatusPengumpulan.belum;
  }

  bool get sudahDikumpulkan =>
      statusPengumpulan != StatusPengumpulan.belum;

  /// Terlambat: sudah lewat deadline dan belum dikumpulkan, atau
  /// backend menandai pengumpulan sebagai terlambat (status = 2).
  bool get isTerlambat {
    final p = pengumpulan;
    if (p != null && p.sudahDikumpulkan) return p.isTerlambat;
    return tugas.isLewatDeadline;
  }

  TugasItemEntity copyWith({TugasSiswaEntity? pengumpulan}) =>
      TugasItemEntity(
        tugas: tugas,
        pengumpulan: pengumpulan ?? this.pengumpulan,
      );

  @override
  List<Object?> get props => [tugas.id, pengumpulan?.id, pengumpulan?.nilai];
}
