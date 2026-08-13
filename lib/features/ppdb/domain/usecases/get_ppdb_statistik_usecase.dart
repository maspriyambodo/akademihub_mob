import '../../../../core/error/result.dart';
import '../entities/ppdb_statistik_entity.dart';
import '../repositories/ppdb_repository.dart';

class GetPpdbStatistikUseCase {
  final PpdbRepository _repository;
  const GetPpdbStatistikUseCase(this._repository);

  Future<Result<PpdbStatistikEntity>> call({
    required int sekolahId,
    int? gelombangId,
  }) =>
      _repository.getStatistik(sekolahId: sekolahId, gelombangId: gelombangId);
}
