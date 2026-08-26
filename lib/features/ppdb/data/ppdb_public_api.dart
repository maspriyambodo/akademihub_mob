import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';

class PpdbPublicApi {
  final Dio _dio;

  const PpdbPublicApi(this._dio);

  Future<List<Map<String, dynamic>>> schools() => _list('/ppdb/public/sekolah');

  Future<List<Map<String, dynamic>>> activeWaves(int schoolId) =>
      _list('/ppdb/public/gelombang/$schoolId/active');

  Future<Map<String, dynamic>> applicationStatus(String number) async {
    final response = await _dio.get(
      '/ppdb/public/status/${Uri.encodeComponent(number)}',
    );
    return _map(response.data);
  }

  Future<Map<String, dynamic>> register({
    required Map<String, dynamic> fields,
    required Map<String, PlatformFile> documents,
  }) async {
    final files = <String, MultipartFile>{};
    for (final entry in documents.entries) {
      final file = entry.value;
      files[entry.key] = file.bytes != null
          ? MultipartFile.fromBytes(file.bytes!, filename: file.name)
          : await MultipartFile.fromFile(file.path!, filename: file.name);
    }
    final response = await _dio.post(
      '/ppdb/public/daftar',
      data: FormData.fromMap({...fields, ...files}),
    );
    return _map(response.data);
  }

  Future<List<Map<String, dynamic>>> _list(String path) async {
    final response = await _dio.get(path);
    final data = _map(response.data)['data'];
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }

  Map<String, dynamic> _map(dynamic body) {
    if (body is Map<String, dynamic>) return body;
    if (body is Map) return Map<String, dynamic>.from(body);
    return const {};
  }
}
