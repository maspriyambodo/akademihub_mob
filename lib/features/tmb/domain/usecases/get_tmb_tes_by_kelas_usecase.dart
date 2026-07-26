import '../../../../core/error/result.dart';
import '../entities/tmb_tes_entity.dart';
import '../repositories/tmb_repository.dart';

class GetTmbTesByKelasUseCase {
  final TmbRepository _repository;
  const GetTmbTesByKelasUseCase(this._repository);

  Future<Result<List<TmbTesEntity>>> call(int kelasId) =>
      _repository.getTesByKelas(kelasId);
}
