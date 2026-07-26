import '../../../../core/error/result.dart';
import '../entities/ppdb_gelombang_entity.dart';
import '../repositories/ppdb_repository.dart';

class GetPpdbGelombangUseCase {
  final PpdbRepository _repository;
  const GetPpdbGelombangUseCase(this._repository);

  Future<Result<List<PpdbGelombangEntity>>> call() =>
      _repository.getGelombangList();
}
