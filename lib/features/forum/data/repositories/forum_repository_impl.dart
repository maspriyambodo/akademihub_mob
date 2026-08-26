import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/forum_entity.dart';
import '../../domain/entities/forum_page_entity.dart';
import '../../domain/repositories/forum_repository.dart';
import '../datasources/forum_remote_datasource.dart';

class ForumRepositoryImpl implements ForumRepository {
  final ForumRemoteDataSource _remote;

  const ForumRepositoryImpl(this._remote);

  @override
  Future<Result<ForumPageEntity>> getForumList({
    String? search,
    int? tipe,
    String? cursor,
    int perPage = 20,
  }) async {
    try {
      final page = await _remote.getForumList(
        search: search,
        tipe: tipe,
        cursor: cursor,
        perPage: perPage,
      );
      return success(page.toEntity());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    } on AppException catch (e) {
      return fail(_map(e));
    }
  }

  @override
  Future<Result<ForumEntity>> getForumDetail(int id) async {
    try {
      final model = await _remote.getForumDetail(id);
      return success(model.toEntity());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    } on AppException catch (e) {
      return fail(_map(e));
    }
  }

  @override
  Future<Result<List<ForumEntity>>> getForumByUser(int userId) async {
    try {
      final models = await _remote.getForumByUser(userId);
      return success(models.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    } on AppException catch (e) {
      return fail(_map(e));
    }
  }

  @override
  Future<Result<ForumEntity>> createForum({
    required int sekolahId,
    required int createdBy,
    required String judul,
    required String konten,
    int? kelasId,
    int? mapelId,
    int? tipe,
    bool? isAnonymous,
  }) async {
    try {
      final model = await _remote.createForum(
        sekolahId: sekolahId,
        createdBy: createdBy,
        judul: judul,
        konten: konten,
        kelasId: kelasId,
        mapelId: mapelId,
        tipe: tipe,
        isAnonymous: isAnonymous,
      );
      return success(model.toEntity());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    } on AppException catch (e) {
      return fail(_map(e));
    }
  }

  @override
  Future<Result<ForumEntity>> updateForum({
    required int id,
    String? judul,
    String? konten,
    int? tipe,
    int? status,
    bool? isAnonymous,
  }) async {
    try {
      final model = await _remote.updateForum(
        id: id,
        judul: judul,
        konten: konten,
        tipe: tipe,
        status: status,
        isAnonymous: isAnonymous,
      );
      return success(model.toEntity());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    } on AppException catch (e) {
      return fail(_map(e));
    }
  }

  @override
  Future<Result<bool>> deleteForum(int id) async {
    try {
      final ok = await _remote.deleteForum(id);
      return success(ok);
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    } on AppException catch (e) {
      return fail(_map(e));
    }
  }

  Failure _map(AppException e) {
    if (e is NetworkException) return NetworkFailure(e.message);
    if (e is AuthException) return AuthFailure(e.message);
    if (e is ForbiddenException) return ForbiddenFailure(e.message);
    if (e is ValidationException) {
      return ValidationFailure(e.message, errors: e.errors);
    }
    if (e is NotFoundException) return NotFoundFailure(e.message);
    return ServerFailure(e.message);
  }
}
