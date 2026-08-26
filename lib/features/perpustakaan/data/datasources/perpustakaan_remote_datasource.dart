import 'package:dio/dio.dart';

class PerpustakaanRemoteDataSource {
  final Dio _dio;
  PerpustakaanRemoteDataSource(this._dio);

  Future<List<Map<String, dynamic>>> availableBooks() =>
      _getList('/perpustakaan/buku/available');
  Future<List<Map<String, dynamic>>> loansForStudent(int siswaId) =>
      _getList('/perpustakaan/peminjaman/siswa/$siswaId');

  Future<List<Map<String, dynamic>>> _getList(String path) async {
    final body = (await _dio.get(path)).data;
    final data = body is Map ? body['data'] : null;
    return data is List
        ? data
              .whereType<Map>()
              .map((x) => Map<String, dynamic>.from(x))
              .toList()
        : const [];
  }
}
