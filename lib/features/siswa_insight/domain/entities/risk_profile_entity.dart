import 'package:equatable/equatable.dart';

/// Profil risiko 5 dimensi dari `GET /siswa/{id}/risk-profile`.
class RiskProfileEntity extends Equatable {
  final int siswaId;
  final int riskScore;
  final String riskCategory; // 'low' | 'medium' | 'high' | 'critical'
  final String trend; // 'naik' | 'turun' | 'stabil'
  final Map<String, dynamic> dimensions;
  final List<String> recommendations;
  final DateTime? computedAt;

  const RiskProfileEntity({
    required this.siswaId,
    required this.riskScore,
    required this.riskCategory,
    required this.trend,
    required this.dimensions,
    required this.recommendations,
    this.computedAt,
  });

  @override
  List<Object?> get props => [
    siswaId,
    riskScore,
    riskCategory,
    trend,
    computedAt,
  ];
}
