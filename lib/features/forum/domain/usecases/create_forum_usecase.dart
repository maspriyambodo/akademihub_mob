import '../../../../core/error/result.dart';
import '../entities/forum_entity.dart';
import '../repositories/forum_repository.dart';

class CreateForumUseCase {
  final ForumRepository _repository;
  const CreateForumUseCase(this._repository);

  Future<Result<ForumEntity>> call({
    required int sekolahId,
    required int createdBy,
    required String judul,
    required String konten,
    int? kelasId,
    int? mapelId,
    int? tipe,
    bool? isAnonymous,
  }) => _repository.createForum(
    sekolahId: sekolahId,
    createdBy: createdBy,
    judul: judul,
    konten: konten,
    kelasId: kelasId,
    mapelId: mapelId,
    tipe: tipe,
    isAnonymous: isAnonymous,
  );
}
