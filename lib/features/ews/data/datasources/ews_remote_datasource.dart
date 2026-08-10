import 'package:dio/dio.dart';

import '../models/ews_alert_model.dart';

abstract class EwsRemoteDataSource {
  Future<List<EwsAlertModel>> getAlerts({
    int? siswaId,
    String? kategori,
    int? level,
    bool? isResolved,
  });

  Future<EwsAlertModel> getAlertDetail(int id);
  Future<void> resolveAlert(int id);
  Future<void> triggerCheck(int siswaId);
}

class EwsRemoteDataSourceImpl implements EwsRemoteDataSource {
  final Dio _dio;

  const EwsRemoteDataSourceImpl(this._dio);

  Map<String, dynamic> _asMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return raw.map((k, v) => MapEntry(k.toString(), v));
    return <String, dynamic>{};
  }

  @override
  Future<List<EwsAlertModel>> getAlerts({
    int? siswaId,
    String? kategori,
    int? level,
    bool? isResolved,
  }) async {
    final query = <String, dynamic>{};
    if (siswaId != null) query['mst_siswa_id'] = siswaId;
    if (kategori != null) query['kategori'] = kategori;
    if (level != null) query['level'] = level;
    if (isResolved != null) {
      query['is_resolved'] = isResolved ? 1 : 0;
    }

    final response = await _dio.get('/ews', queryParameters: query);
    final body = _asMap(response.data);
    final list = body['data'];
    if (list is List) {
      return list
          .whereType<Map>()
          .map((e) => EwsAlertModel.fromJson(e.cast<String, dynamic>()))
          .toList();
    }
    return const [];
  }

  @override
  Future<EwsAlertModel> getAlertDetail(int id) async {
    final response = await _dio.get('/ews/$id');
    final body = _asMap(response.data);
    final data = body['data'];
    if (data is Map) {
      return EwsAlertModel.fromJson(data.cast<String, dynamic>());
    }
    throw const FormatException('Format respons detail EWS tidak valid');
  }

  @override
  Future<void> resolveAlert(int id) async {
    await _dio.put('/ews/$id/resolve');
  }

  @override
  Future<void> triggerCheck(int siswaId) async {
    await _dio.post('/ews/$siswaId/trigger');
  }
}
