import '../../domain/entities/risk_profile_entity.dart';
import '../../domain/entities/siswa_insight_entity.dart';

class SiswaInsightModel {
  final Map<String, dynamic> siswa;
  final Map<String, dynamic>? riskProfile;
  final Map<String, dynamic>? academicProgress;
  final Map<String, dynamic>? kehadiranSummary;
  final Map<String, dynamic>? tugasSummary;
  final Map<String, dynamic>? sppSummary;
  final Map<String, dynamic>? ewsSummary;
  final Map<String, dynamic> activityHeatmap;
  final DateTime? computedAt;

  const SiswaInsightModel({
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

  factory SiswaInsightModel.fromJson(Map<String, dynamic> json) {
    return SiswaInsightModel(
      siswa: _asMap(json['siswa']),
      riskProfile: _asMapOrNull(json['risk_profile']),
      academicProgress: _asMapOrNull(json['academic_progress']),
      kehadiranSummary: _asMapOrNull(json['kehadiran_summary']),
      tugasSummary: _asMapOrNull(json['tugas_summary']),
      sppSummary: _asMapOrNull(json['spp_summary']),
      ewsSummary: _asMapOrNull(json['ews_summary']),
      activityHeatmap: _asMap(json['activity_heatmap']),
      computedAt: _parseDate(json['computed_at']),
    );
  }

  SiswaInsightEntity toEntity() => SiswaInsightEntity(
    siswa: siswa,
    riskProfile: riskProfile,
    academicProgress: academicProgress,
    kehadiranSummary: kehadiranSummary,
    tugasSummary: tugasSummary,
    sppSummary: sppSummary,
    ewsSummary: ewsSummary,
    activityHeatmap: activityHeatmap,
    computedAt: computedAt,
  );

  static Map<String, dynamic> _asMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return raw.map((k, v) => MapEntry(k.toString(), v));
    return <String, dynamic>{};
  }

  static Map<String, dynamic>? _asMapOrNull(dynamic raw) {
    if (raw is Map) return _asMap(raw);
    return null;
  }

  static DateTime? _parseDate(dynamic raw) {
    if (raw is! String || raw.isEmpty) return null;
    return DateTime.tryParse(raw)?.toLocal();
  }
}

class RiskProfileModel {
  final int siswaId;
  final int riskScore;
  final String riskCategory;
  final String trend;
  final Map<String, dynamic> dimensions;
  final List<String> recommendations;
  final DateTime? computedAt;

  const RiskProfileModel({
    required this.siswaId,
    required this.riskScore,
    required this.riskCategory,
    required this.trend,
    required this.dimensions,
    required this.recommendations,
    this.computedAt,
  });

  factory RiskProfileModel.fromJson(Map<String, dynamic> json) {
    final dims = json['dimensions'];
    return RiskProfileModel(
      siswaId: (json['siswa_id'] as num?)?.toInt() ?? 0,
      riskScore: (json['risk_score'] as num?)?.toInt() ?? 0,
      riskCategory: json['risk_category'] as String? ?? 'low',
      trend: json['trend'] as String? ?? 'stabil',
      dimensions: dims is Map
          ? dims.map((k, v) => MapEntry(k.toString(), v))
          : <String, dynamic>{},
      recommendations: (json['recommendations'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      computedAt: SiswaInsightModel._parseDate(json['computed_at']),
    );
  }

  RiskProfileEntity toEntity() => RiskProfileEntity(
    siswaId: siswaId,
    riskScore: riskScore,
    riskCategory: riskCategory,
    trend: trend,
    dimensions: dimensions,
    recommendations: recommendations,
    computedAt: computedAt,
  );
}
