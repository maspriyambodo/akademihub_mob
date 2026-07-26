import '../../../../core/error/result.dart';
import '../repositories/ujian_repository.dart';

class ExportRankingUseCase {
  final UjianRepository _repository;
  const ExportRankingUseCase(this._repository);

  /// Mengembalikan path file xlsx lokal.
  Future<Result<String>> call({
    required int kelasId,
    required int semesterId,
    required int tahunAjaranId,
  }) => _repository.exportRanking(
    kelasId: kelasId,
    semesterId: semesterId,
    tahunAjaranId: tahunAjaranId,
  );
}
