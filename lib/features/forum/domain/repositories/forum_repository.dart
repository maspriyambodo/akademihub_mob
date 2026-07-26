import '../../../../core/error/result.dart';
import '../entities/forum_entity.dart';
import '../entities/forum_page_entity.dart';

abstract class ForumRepository {
  /// Daftar post forum (terpaginasi cursor, terurut `created_at` desc).
  ///
  /// [search] dan [tipe] benar-benar diterapkan di backend
  /// (`ForumService::applyBaseFilters`).
  Future<Result<ForumPageEntity>> getForumList({
    String? search,
    int? tipe,
    String? cursor,
    int perPage,
  });

  /// Detail satu post.
  Future<Result<ForumEntity>> getForumDetail(int id);

  /// Post milik satu user (`GET /akademik/forum/user/{userId}`).
  Future<Result<List<ForumEntity>>> getForumByUser(int userId);

  /// Buat post baru — butuh permission `forum.create`.
  Future<Result<ForumEntity>> createForum({
    required int sekolahId,
    required int createdBy,
    required String judul,
    required String konten,
    int? kelasId,
    int? mapelId,
    int? tipe,
    bool? isAnonymous,
  });

  /// Ubah post — butuh permission `forum.update`.
  Future<Result<ForumEntity>> updateForum({
    required int id,
    String? judul,
    String? konten,
    int? tipe,
    int? status,
    bool? isAnonymous,
  });

  /// Hapus post (soft delete di backend) — butuh permission `forum.delete`.
  Future<Result<bool>> deleteForum(int id);
}
