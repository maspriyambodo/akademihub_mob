import '../../../../core/error/result.dart';
import '../entities/risk_profile_entity.dart';
import '../entities/siswa_insight_entity.dart';

abstract class SiswaInsightRepository {
  /// Dashboard 360° lengkap untuk satu siswa.
  /// Endpoint: `GET /api/v1/siswa/{id}/insight`.
  Future<Result<SiswaInsightEntity>> getInsight(
    int siswaId, {
    bool refresh = false,
  });

  /// Profil risiko 5 dimensi.
  /// Endpoint: `GET /api/v1/siswa/{id}/risk-profile`.
  Future<Result<RiskProfileEntity>> getRiskProfile(
    int siswaId, {
    bool refresh = false,
  });

  /// Progres akademik (tren, anomali, proyeksi).
  /// Endpoint: `GET /api/v1/siswa/{id}/academic-progress`.
  Future<Result<Map<String, dynamic>>> getAcademicProgress(
    int siswaId, {
    bool refresh = false,
  });

  /// Invalidate cache insight.
  /// Endpoint: `POST /api/v1/siswa/{id}/insight/invalidate`.
  Future<Result<void>> invalidateCache(int siswaId);
}
