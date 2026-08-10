import '../../../../core/error/result.dart';
import '../entities/siswa_insight_entity.dart';
import '../repositories/siswa_insight_repository.dart';

class GetSiswaInsightUseCase {
  final SiswaInsightRepository repository;

  const GetSiswaInsightUseCase(this.repository);

  Future<Result<SiswaInsightEntity>> call(int siswaId, {bool refresh = false}) {
    return repository.getInsight(siswaId, refresh: refresh);
  }
}
