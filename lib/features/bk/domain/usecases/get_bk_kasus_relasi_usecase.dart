import '../../../../core/error/result.dart';
import '../entities/bk_hasil_entity.dart';
import '../entities/bk_sesi_entity.dart';
import '../entities/bk_tindakan_entity.dart';
import '../repositories/bk_repository.dart';

class GetBkSesiByKasusUseCase {
  final BkRepository _repository;
  const GetBkSesiByKasusUseCase(this._repository);

  Future<Result<List<BkSesiEntity>>> call(int kasusId) =>
      _repository.getSesiByKasus(kasusId);
}

class GetBkHasilByKasusUseCase {
  final BkRepository _repository;
  const GetBkHasilByKasusUseCase(this._repository);

  Future<Result<List<BkHasilEntity>>> call(int kasusId) =>
      _repository.getHasilByKasus(kasusId);
}

class GetBkTindakanByKasusUseCase {
  final BkRepository _repository;
  const GetBkTindakanByKasusUseCase(this._repository);

  Future<Result<List<BkTindakanEntity>>> call(int kasusId) =>
      _repository.getTindakanByKasus(kasusId);
}
