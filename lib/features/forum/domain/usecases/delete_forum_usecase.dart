import '../../../../core/error/result.dart';
import '../repositories/forum_repository.dart';

class DeleteForumUseCase {
  final ForumRepository _repository;
  const DeleteForumUseCase(this._repository);

  Future<Result<bool>> call(int id) => _repository.deleteForum(id);
}
