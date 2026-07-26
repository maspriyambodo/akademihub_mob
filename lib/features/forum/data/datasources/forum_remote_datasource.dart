import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../models/forum_model.dart';
import '../models/forum_page_model.dart';

abstract class ForumRemoteDataSource {
  Future<ForumPageModel> getForumList({
    String? search,
    int? tipe,
    String? cursor,
    int perPage,
  });

  Future<ForumModel> getForumDetail(int id);

  Future<List<ForumModel>> getForumByUser(int userId);

  Future<ForumModel> createForum({
    required int sekolahId,
    required int createdBy,
    required String judul,
    required String konten,
    int? kelasId,
    int? mapelId,
    int? tipe,
    bool? isAnonymous,
  });

  Future<ForumModel> updateForum({
    required int id,
    String? judul,
    String? konten,
    int? tipe,
    int? status,
    bool? isAnonymous,
  });

  Future<bool> deleteForum(int id);
}

class ForumRemoteDataSourceImpl implements ForumRemoteDataSource {
  final Dio _dio;

  const ForumRemoteDataSourceImpl(this._dio);

  /// `ForumController::index` memakai `AgGridControllerTrait`:
  /// - tanpa `startRow`/`endRow` → `paginatedResponse`: `{ "data": [...],
  ///   "meta": { next_cursor, prev_cursor, has_more, total } }`
  /// - dengan `startRow`/`endRow` → `agGridResponse`: `{ "rowData": [...] }`
  ///
  /// Kita sengaja memakai mode tradisional karena hanya jalur itu yang
  /// menjamin urutan `created_at DESC` (mode AG Grid tanpa `sortModel`
  /// jatuh ke `ORDER BY id ASC`). Filter `search`/`tipe` tetap diterapkan
  /// backend di kedua jalur (`ForumService::applyBaseFilters`).
  /// Parser di bawah tetap menangani ketiga bentuk response.
  List<dynamic> _extractList(dynamic body) {
    if (body is! Map) return const [];

    final rowData = body['rowData'];
    if (rowData is List) return rowData;

    final raw = body['data'];
    if (raw is List) return raw;
    if (raw is Map) {
      final nested = raw['data'];
      if (nested is List) return nested;
    }
    return const [];
  }

  Map<String, dynamic> _extractObject(dynamic body) {
    if (body is Map) {
      final raw = body['data'];
      if (raw is Map<String, dynamic>) return raw;
      if (raw is Map) return Map<String, dynamic>.from(raw);
    }
    return <String, dynamic>{};
  }

  List<ForumModel> _parseList(dynamic body) {
    final result = <ForumModel>[];
    for (final item in _extractList(body)) {
      if (item is Map<String, dynamic>) {
        result.add(ForumModel.fromJson(item));
      } else if (item is Map) {
        result.add(ForumModel.fromJson(Map<String, dynamic>.from(item)));
      }
    }
    return result;
  }

  @override
  Future<ForumPageModel> getForumList({
    String? search,
    int? tipe,
    String? cursor,
    int perPage = 20,
  }) async {
    final response = await _dio.get(
      '/akademik/forum',
      queryParameters: <String, dynamic>{
        'per_page': perPage,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        'tipe': ?tipe,
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
      },
    );

    final body = response.data;
    final meta = body is Map ? body['meta'] : null;

    String? nextCursor;
    bool hasMore = false;
    int? total;
    if (meta is Map) {
      nextCursor = meta['next_cursor'] as String?;
      final rawHasMore = meta['has_more'];
      hasMore = rawHasMore is bool ? rawHasMore : nextCursor != null;
      total = (meta['total'] as num?)?.toInt();
    }

    final items = _parseList(body);
    // Pengaman: bila meta tidak dikirim (mis. jalur AG Grid), anggap habis.
    if (nextCursor == null) hasMore = false;

    return ForumPageModel(
      items: items,
      nextCursor: nextCursor,
      hasMore: hasMore,
      total: total,
    );
  }

  @override
  Future<ForumModel> getForumDetail(int id) async {
    final response = await _dio.get('/akademik/forum/$id');
    final raw = _extractObject(response.data);
    if (raw.isEmpty) {
      throw const NotFoundException('Topik forum tidak ditemukan');
    }
    return ForumModel.fromJson(raw);
  }

  @override
  Future<List<ForumModel>> getForumByUser(int userId) async {
    final response = await _dio.get('/akademik/forum/user/$userId');
    return _parseList(response.data);
  }

  @override
  Future<ForumModel> createForum({
    required int sekolahId,
    required int createdBy,
    required String judul,
    required String konten,
    int? kelasId,
    int? mapelId,
    int? tipe,
    bool? isAnonymous,
  }) async {
    // `sekolah_id` dan `created_by` WAJIB menurut `CreateForumRequest` —
    // backend tidak mengisinya otomatis dari sesi.
    final body = <String, dynamic>{
      'sekolah_id': sekolahId,
      'created_by': createdBy,
      'judul': judul,
      'konten': konten,
      'kelas_id': ?kelasId,
      'mapel_id': ?mapelId,
      'tipe': ?tipe,
      'is_anonymous': ?isAnonymous,
    };

    final response = await _dio.post('/akademik/forum', data: body);
    final raw = _extractObject(response.data);
    if (raw.isEmpty) {
      throw const ServerException('Respons pembuatan topik tidak valid');
    }
    return ForumModel.fromJson(raw);
  }

  @override
  Future<ForumModel> updateForum({
    required int id,
    String? judul,
    String? konten,
    int? tipe,
    int? status,
    bool? isAnonymous,
  }) async {
    // `UpdateForumRequest` memakai rule `sometimes` → kirim hanya yang berubah.
    final body = <String, dynamic>{
      'judul': ?judul,
      'konten': ?konten,
      'tipe': ?tipe,
      'status': ?status,
      'is_anonymous': ?isAnonymous,
    };

    final response = await _dio.put('/akademik/forum/$id', data: body);
    final raw = _extractObject(response.data);
    if (raw.isEmpty) {
      throw const ServerException('Respons perubahan topik tidak valid');
    }
    return ForumModel.fromJson(raw);
  }

  @override
  Future<bool> deleteForum(int id) async {
    // Response sukses: `{ "success": true, "message": ..., "data": null }`.
    await _dio.delete('/akademik/forum/$id');
    return true;
  }
}
