import 'package:dio/dio.dart';

class OrganisasiRemoteDataSource {
  final Dio _dio;

  const OrganisasiRemoteDataSource(this._dio);

  List<Map<String, dynamic>> _list(dynamic body) {
    if (body is! Map) return const [];
    final data = body['rowData'] ?? body['data'];
    final items = data is Map ? data['data'] : data;
    return items is List
        ? items.whereType<Map<String, dynamic>>().toList()
        : const [];
  }

  Map<String, dynamic>? _item(dynamic body) {
    final data = body is Map ? body['data'] : null;
    return data is Map<String, dynamic> ? data : null;
  }

  Future<List<Map<String, dynamic>>> list() async => _list(
    (await _dio.get(
      '/organisasi',
      queryParameters: {'startRow': 0, 'endRow': 300},
    )).data,
  );

  Future<Map<String, dynamic>?> detail(int id) async =>
      _item((await _dio.get('/organisasi/$id')).data);

  Future<List<Map<String, dynamic>>> anggota(int organisasiId) async => _list(
    (await _dio.get('/organisasi/anggota/organisasi/$organisasiId')).data,
  );
}
