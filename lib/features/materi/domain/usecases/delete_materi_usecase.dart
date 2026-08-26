import '../../../../core/error/result.dart';
import '../repositories/materi_repository.dart';

class DeleteMateriUseCase {
  final MateriRepository _repository;
  const DeleteMateriUseCase(this._repository);

  Future<Result<bool>> call(int id) => _repository.deleteMateri(id);
}
