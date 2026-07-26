import '../../../../core/error/result.dart';
import '../entities/bk_sesi_entity.dart';
import '../repositories/bk_repository.dart';

class CreateBkSesiUseCase {
  final BkRepository _repository;
  const CreateBkSesiUseCase(this._repository);

  Future<Result<BkSesiEntity>> call({
    required int kasusId,
    required String tanggal,
    required int metode,
    required String catatan,
  }) => _repository.createSesi(
    kasusId: kasusId,
    tanggal: tanggal,
    metode: metode,
    catatan: catatan,
  );
}
