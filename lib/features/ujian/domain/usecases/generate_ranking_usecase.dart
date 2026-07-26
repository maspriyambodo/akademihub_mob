import '../../../../core/error/result.dart';
import '../entities/ranking_entity.dart';
import '../repositories/ujian_repository.dart';

class GenerateRankingUseCase {
  final UjianRepository _repository;
  const GenerateRankingUseCase(this._repository);

  Future<Result<List<RankingEntity>>> call({
    required int kelasId,
    required int semesterId,
    required int tahunAjaranId,
  }) => _repository.generateRanking(
    kelasId: kelasId,
    semesterId: semesterId,
    tahunAjaranId: tahunAjaranId,
  );
}
