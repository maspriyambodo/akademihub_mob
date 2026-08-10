import '../../../../core/error/result.dart';
import '../repositories/siswa_insight_repository.dart';

class InvalidateSiswaInsightCacheUseCase {
  final SiswaInsightRepository repository;

  const InvalidateSiswaInsightCacheUseCase(this.repository);

  Future<Result<void>> call(int siswaId) {
    return repository.invalidateCache(siswaId);
  }
}
