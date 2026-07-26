import '../../../../core/error/result.dart';
import '../entities/tmb_tes_entity.dart';
import '../repositories/tmb_repository.dart';

class GetTmbTesListUseCase {
  final TmbRepository _repository;
  const GetTmbTesListUseCase(this._repository);

  Future<Result<List<TmbTesEntity>>> call() => _repository.getTesList();
}
