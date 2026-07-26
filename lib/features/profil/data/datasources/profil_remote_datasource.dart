import 'package:dio/dio.dart';

import '../models/perangkat_model.dart';
import '../models/sekolah_model.dart';

abstract class ProfilRemoteDataSource {
  Future<SekolahModel> getSekolahById(int id);
  Future<SekolahModel> getSekolahByUuid(String uuid);
  Future<List<SekolahModel>> getSekolahList({String? search});
  Future<List<PerangkatModel>> getPerangkatUser(int userId);
}

class ProfilRemoteDataSourceImpl implements ProfilRemoteDataSource {
  final Dio _dio;

  const ProfilRemoteDataSourceImpl(this._dio);

  /// `SekolahController@index` memakai `AgGridControllerTrait`:
  /// - tanpa `startRow`/`endRow` → `{ "data": [...] }` (kadang
  ///   `{ "data": { "data": [...] } }` bila paginator ikut terbawa);
  /// - dengan `startRow`/`endRow` → `{ "rowData": [...] }`.
  /// Endpoint device membalas `{ "data": [...] }` biasa.
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

  Map<String, dynamic>? _extractMap(dynamic body) {
    if (body is! Map) return null;
    final raw = body['data'];
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }

  @override
  Future<SekolahModel> getSekolahById(int id) async {
    final response = await _dio.get('/sekolah/$id');
    final map = _extractMap(response.data);
    if (map == null) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: Response<dynamic>(
          requestOptions: response.requestOptions,
          statusCode: 404,
          data: const {'message': 'Data sekolah tidak ditemukan'},
        ),
        type: DioExceptionType.badResponse,
      );
    }
    return SekolahModel.fromJson(map);
  }

  @override
  Future<SekolahModel> getSekolahByUuid(String uuid) async {
    final response = await _dio.get('/sekolah/uuid/$uuid');
    final map = _extractMap(response.data);
    if (map == null) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: Response<dynamic>(
          requestOptions: response.requestOptions,
          statusCode: 404,
          data: const {'message': 'Data sekolah tidak ditemukan'},
        ),
        type: DioExceptionType.badResponse,
      );
    }
    return SekolahModel.fromJson(map);
  }

  @override
  Future<List<SekolahModel>> getSekolahList({String? search}) async {
    // Filter `search` diterapkan `SekolahService@getAllSekolah`
    // (ilike pada nama_sekolah / npsn) juga di mode non-AG-Grid.
    final response = await _dio.get(
      '/sekolah',
      queryParameters: <String, dynamic>{
        'per_page': 50,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      },
    );
    final list = _extractList(response.data);
    final result = <SekolahModel>[];
    for (final item in list) {
      if (item is Map<String, dynamic>) {
        result.add(SekolahModel.fromJson(item));
      } else if (item is Map) {
        result.add(SekolahModel.fromJson(Map<String, dynamic>.from(item)));
      }
    }
    return result;
  }

  @override
  Future<List<PerangkatModel>> getPerangkatUser(int userId) async {
    final response = await _dio.get('/admin/user-devices/user/$userId');
    final list = _extractList(response.data);
    final result = <PerangkatModel>[];
    for (final item in list) {
      if (item is Map<String, dynamic>) {
        result.add(PerangkatModel.fromJson(item));
      } else if (item is Map) {
        result.add(PerangkatModel.fromJson(Map<String, dynamic>.from(item)));
      }
    }
    return result;
  }
}
