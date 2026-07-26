import '../../../../core/error/result.dart';
import '../entities/forum_entity.dart';
import '../repositories/forum_repository.dart';

class UpdateForumUseCase {
  final ForumRepository _repository;
  const UpdateForumUseCase(this._repository);

  Future<Result<ForumEntity>> call({
    required int id,
    String? judul,
    String? konten,
    int? tipe,
    int? status,
    bool? isAnonymous,
  }) => _repository.updateForum(
    id: id,
    judul: judul,
    konten: konten,
    tipe: tipe,
    status: status,
    isAnonymous: isAnonymous,
  );
}
