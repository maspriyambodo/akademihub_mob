import '../../../../core/error/result.dart';
import '../entities/bk_hasil_entity.dart';
import '../repositories/bk_repository.dart';

class CreateBkHasilUseCase {
  final BkRepository _repository;
  const CreateBkHasilUseCase(this._repository);

  Future<Result<BkHasilEntity>> call({
    required int kasusId,
    required String hasil,
    required String rekomendasi,
  }) => _repository.createHasil(
    kasusId: kasusId,
    hasil: hasil,
    rekomendasi: rekomendasi,
  );
}
