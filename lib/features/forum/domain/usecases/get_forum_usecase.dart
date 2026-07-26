import '../../../../core/error/result.dart';
import '../entities/forum_entity.dart';
import '../entities/forum_page_entity.dart';
import '../repositories/forum_repository.dart';

class GetForumListUseCase {
  final ForumRepository _repository;
  const GetForumListUseCase(this._repository);

  Future<Result<ForumPageEntity>> call({
    String? search,
    int? tipe,
    String? cursor,
    int perPage = 20,
  }) => _repository.getForumList(
    search: search,
    tipe: tipe,
    cursor: cursor,
    perPage: perPage,
  );
}

class GetForumDetailUseCase {
  final ForumRepository _repository;
  const GetForumDetailUseCase(this._repository);

  Future<Result<ForumEntity>> call(int id) => _repository.getForumDetail(id);
}

class GetForumByUserUseCase {
  final ForumRepository _repository;
  const GetForumByUserUseCase(this._repository);

  Future<Result<List<ForumEntity>>> call(int userId) =>
      _repository.getForumByUser(userId);
}
