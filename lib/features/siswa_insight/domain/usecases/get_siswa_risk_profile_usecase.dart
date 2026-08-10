import '../../../../core/error/result.dart';
import '../entities/risk_profile_entity.dart';
import '../repositories/siswa_insight_repository.dart';

class GetSiswaRiskProfileUseCase {
  final SiswaInsightRepository repository;

  const GetSiswaRiskProfileUseCase(this.repository);

  Future<Result<RiskProfileEntity>> call(int siswaId, {bool refresh = false}) {
    return repository.getRiskProfile(siswaId, refresh: refresh);
  }
}
