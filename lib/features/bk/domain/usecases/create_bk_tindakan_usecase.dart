import '../../../../core/error/result.dart';
import '../entities/bk_tindakan_entity.dart';
import '../repositories/bk_repository.dart';

class CreateBkTindakanUseCase {
  final BkRepository _repository;
  const CreateBkTindakanUseCase(this._repository);

  Future<Result<BkTindakanEntity>> call({
    required int kasusId,
    required String deskripsi,
  }) => _repository.createTindakan(kasusId: kasusId, deskripsi: deskripsi);
}
