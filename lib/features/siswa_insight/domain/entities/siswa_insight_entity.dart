import 'package:equatable/equatable.dart';

class SiswaInsightEntity extends Equatable {
  final Map<String, dynamic> siswa;
  final Map<String, dynamic>? riskProfile;
  final Map<String, dynamic>? academicProgress;
  final Map<String, dynamic>? kehadiranSummary;
  final Map<String, dynamic>? tugasSummary;
  final Map<String, dynamic>? sppSummary;
  final Map<String, dynamic>? ewsSummary;
  final Map<String, dynamic> activityHeatmap;
  final DateTime? computedAt;

  const SiswaInsightEntity({
    required this.siswa,
    this.riskProfile,
    this.academicProgress,
    this.kehadiranSummary,
    this.tugasSummary,
    this.sppSummary,
    this.ewsSummary,
    required this.activityHeatmap,
    this.computedAt,
  });

  String get namaSiswa => siswa['nama']?.toString() ?? 'Siswa';
  String? get nis => siswa['nis']?.toString();
  String? get kelas => siswa['kelas']?.toString();
  String? get status => siswa['status']?.toString();

  @override
  List<Object?> get props => [siswa, computedAt];
}
