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

    final response = await _dio.get('/ews/alerts', queryParameters: query);
    final body = _asMap(response.data);
    final raw = body['data'];
    final list = raw is Map ? raw['data'] : raw;
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
    final response = await _dio.get('/ews/alerts/$id');
    final body = _asMap(response.data);
    final raw = body['data'];
    if (raw is Map) {
      return EwsAlertModel.fromJson(raw.cast<String, dynamic>());
    }
    return EwsAlertModel.fromJson(body);
  }

  @override
  Future<void> resolveAlert(int id) async {
    await _dio.patch('/ews/alerts/$id/resolve');
  }

  @override
  Future<void> triggerCheck(int siswaId) async {
    await _dio.post('/ews/process-siswa/$siswaId');
  }
}
