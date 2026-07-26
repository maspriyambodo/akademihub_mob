import '../../../../core/error/result.dart';
import '../entities/bk_kasus_entity.dart';
import '../repositories/bk_repository.dart';

class GetBkKasusListUseCase {
  final BkRepository _repository;
  const GetBkKasusListUseCase(this._repository);

  Future<Result<List<BkKasusEntity>>> call() => _repository.getKasusList();
}

class GetBkKasusBySiswaUseCase {
  final BkRepository _repository;
  const GetBkKasusBySiswaUseCase(this._repository);

  Future<Result<List<BkKasusEntity>>> call(int siswaId) =>
      _repository.getKasusBySiswa(siswaId);
}
