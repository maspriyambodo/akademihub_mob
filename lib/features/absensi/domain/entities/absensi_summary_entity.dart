import 'package:equatable/equatable.dart';

class AbsensiSummaryEntity extends Equatable {
  final int hadir;
  final int izin;
  final int sakit;
  final int alpha;
  final int total;

  const AbsensiSummaryEntity({
    required this.hadir,
    required this.izin,
    required this.sakit,
    required this.alpha,
    required this.total,
  });

  const AbsensiSummaryEntity.empty()
    : hadir = 0,
      izin = 0,
      sakit = 0,
      alpha = 0,
      total = 0;

  double get persentaseHadir => total > 0 ? (hadir / total * 100) : 0.0;

  @override
  List<Object?> get props => [hadir, izin, sakit, alpha, total];
}
