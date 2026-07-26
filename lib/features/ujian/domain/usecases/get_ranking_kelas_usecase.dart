import '../../../../core/error/result.dart';
import '../entities/ranking_entity.dart';
import '../repositories/ujian_repository.dart';

class GetRankingKelasUseCase {
  final UjianRepository _repository;
  const GetRankingKelasUseCase(this._repository);

  Future<Result<List<RankingEntity>>> call(int kelasId) =>
      _repository.getRankingByKelas(kelasId);
}
