import 'package:dio/dio.dart';
import '../models/nilai_model.dart';

abstract class NilaiRemoteDataSource {
  Future<List<NilaiModel>> getNilaiBySiswa(int siswaId);
  Future<List<NilaiModel>> getNilaiByUjian(int ujianId);
  Future<List<NilaiModel>> getNilaiGeneral({
    int? siswaId,
    int? ujianId,
    int perPage = 100,
  });
  Future<double?> getRataRataSiswa(int siswaId);
  Future<NilaiModel> createNilai({
    required int siswaId,
    required int ujianId,
    required double nilai,
    String? keterangan,
  });
  Future<NilaiModel> updateNilai({
    required int id,
    int? siswaId,
    int? ujianId,
    double? nilai,
    String? keterangan,
  });
  Future<bool> deleteNilai(int id);
}

class NilaiRemoteDataSourceImpl implements NilaiRemoteDataSource {
  final Dio _dio;

  const NilaiRemoteDataSourceImpl(this._dio);

  @override
  Future<List<NilaiModel>> getNilaiBySiswa(int siswaId) async {
    final response = await _dio.get('/akademik/nilai/siswa/$siswaId');
    return _parseList(response.data);
  }

  @override
  Future<List<NilaiModel>> getNilaiByUjian(int ujianId) async {
    final response = await _dio.get('/akademik/nilai/ujian/$ujianId');
    return _parseList(response.data);
  }

  @override
  Future<List<NilaiModel>> getNilaiGeneral({
    int? siswaId,
    int? ujianId,
    int perPage = 100,
  }) async {
    final response = await _dio.get(
      '/akademik/nilai',
      queryParameters: {
        'siswa_id': siswaId,
        'ujian_id': ujianId,
        'per_page': perPage,
      }..removeWhere((_, v) => v == null),
    );
    return _parseList(response.data);
  }

  @override
  Future<double?> getRataRataSiswa(int siswaId) async {
    final response = await _dio.get('/akademik/nilai/siswa/$siswaId/rata-rata');
    final raw = response.data is Map<String, dynamic>
        ? (response.data as Map<String, dynamic>)['data']
        : null;
    // Backend membalas { "success": true, "data": { "rata_rata": 85.5 } }
    if (raw is Map) return NilaiModel.parseNilai(raw['rata_rata']);
    return NilaiModel.parseNilai(raw);
  }

  @override
  Future<NilaiModel> createNilai({
    required int siswaId,
    required int ujianId,
    required double nilai,
    String? keterangan,
  }) async {
    final response = await _dio.post(
      '/akademik/nilai',
      data: {
        'mst_siswa_id': siswaId,
        'trx_ujian_id': ujianId,
        'nilai': nilai,
        'keterangan': ?keterangan,
      },
    );
    return NilaiModel.fromJson(_parseObject(response.data));
  }

  @override
  Future<NilaiModel> updateNilai({
    required int id,
    int? siswaId,
    int? ujianId,
    double? nilai,
    String? keterangan,
  }) async {
    final response = await _dio.put(
      '/akademik/nilai/$id',
      data: {
        'mst_siswa_id': ?siswaId,
        'trx_ujian_id': ?ujianId,
        'nilai': ?nilai,
        'keterangan': ?keterangan,
      },
    );
    return NilaiModel.fromJson(_parseObject(response.data));
  }

  @override
  Future<bool> deleteNilai(int id) async {
    await _dio.delete('/akademik/nilai/$id');
    return true;
  }

  /// `data` bisa berupa List langsung (endpoint koleksi) ATAU Map dengan key
  /// `data` di dalamnya (paginator).
  List<NilaiModel> _parseList(dynamic body) {
    final raw = body is Map<String, dynamic> ? body['data'] : null;
    final List<dynamic> list;
    if (raw is List) {
      list = raw;
    } else {
      list = (raw as Map<String, dynamic>?)?['data'] as List<dynamic>? ?? [];
    }
    return list
        .whereType<Map<String, dynamic>>()
        .map(NilaiModel.fromJson)
        .toList();
  }

  Map<String, dynamic> _parseObject(dynamic body) {
    if (body is Map<String, dynamic> && body['data'] is Map<String, dynamic>) {
      return body['data'] as Map<String, dynamic>;
    }
    if (body is Map) return Map<String, dynamic>.from(body);
    return const {};
  }
}
