import '../../../../core/error/result.dart';
import '../repositories/nilai_repository.dart';

class DeleteNilaiUseCase {
  final NilaiRepository _repository;
  const DeleteNilaiUseCase(this._repository);

  Future<Result<bool>> call(int id) => _repository.deleteNilai(id);
}
