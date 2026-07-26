import '../../../../core/error/result.dart';
import '../entities/bk_jenis_entity.dart';
import '../repositories/bk_repository.dart';

class GetBkJenisListUseCase {
  final BkRepository _repository;
  const GetBkJenisListUseCase(this._repository);

  Future<Result<List<BkJenisEntity>>> call() => _repository.getJenisList();
}
