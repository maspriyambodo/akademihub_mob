import 'package:dio/dio.dart';

import '../models/siswa_insight_model.dart';

abstract class SiswaInsightRemoteDataSource {
  Future<SiswaInsightModel> getInsight(int siswaId, {bool refresh = false});
  Future<RiskProfileModel> getRiskProfile(int siswaId, {bool refresh = false});
  Future<Map<String, dynamic>> getAcademicProgress(
    int siswaId, {
    bool refresh = false,
  });
  Future<void> invalidateCache(int siswaId);
}

class SiswaInsightRemoteDataSourceImpl implements SiswaInsightRemoteDataSource {
  final Dio _dio;

  const SiswaInsightRemoteDataSourceImpl(this._dio);

  Map<String, dynamic> _asMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return raw.map((k, v) => MapEntry(k.toString(), v));
    return <String, dynamic>{};
  }

  @override
  Future<SiswaInsightModel> getInsight(int siswaId, {bool refresh = false}) async {
    final response = await _dio.get(
      '/siswa/$siswaId/insight',
      queryParameters: refresh ? {'refresh': 1} : null,
    );
    final body = _asMap(response.data);
    final data = body['data'];
    if (data is Map) {
      return SiswaInsightModel.fromJson(data.cast<String, dynamic>());
    }
    throw const FormatException('Format respons insight tidak valid');
  }

  @override
  Future<RiskProfileModel> getRiskProfile(
    int siswaId, {
    bool refresh = false,
  }) async {
    final response = await _dio.get(
      '/siswa/$siswaId/risk-profile',
      queryParameters: refresh ? {'refresh': 1} : null,
    );
    final body = _asMap(response.data);
    final data = body['data'];
    if (data is Map) {
      return RiskProfileModel.fromJson(data.cast<String, dynamic>());
    }
    throw const FormatException('Format respons risk-profile tidak valid');
  }

  @override
  Future<Map<String, dynamic>> getAcademicProgress(
    int siswaId, {
    bool refresh = false,
  }) async {
    final response = await _dio.get(
      '/siswa/$siswaId/academic-progress',
      queryParameters: refresh ? {'refresh': 1} : null,
    );
    final body = _asMap(response.data);
    final data = body['data'];
    if (data is Map) {
      return data.map((k, v) => MapEntry(k.toString(), v));
    }
    return <String, dynamic>{};
  }

  @override
  Future<void> invalidateCache(int siswaId) async {
    await _dio.post('/siswa/$siswaId/insight/invalidate');
  }
}
