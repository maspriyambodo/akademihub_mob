import 'package:dio/dio.dart';
import '../models/tv_pairing_model.dart';

abstract class TvRemoteDataSource {
  Future<TvPairingSessionModel> createPairingSession({
    required String installationId,
    required String deviceName,
    required String appVersion,
  });

  Future<TvPairingStatusModel> getPairingStatus({
    required String sessionId,
    required String installationId,
  });

  Future<Response<dynamic>> getSnapshot({
    required String deviceToken,
    String? etag,
  });

  Future<void> unpairCurrent({required String deviceToken});
}

class TvRemoteDataSourceImpl implements TvRemoteDataSource {
  final Dio _dio;

  const TvRemoteDataSourceImpl(this._dio);

  @override
  Future<TvPairingSessionModel> createPairingSession({
    required String installationId,
    required String deviceName,
    required String appVersion,
  }) async {
    final response = await _dio.post(
      '/tv/pairing/sessions',
      data: {
        'installation_id': installationId,
        'device_name': deviceName,
        'app_version': appVersion,
      },
    );
    final body = response.data as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>;
    return TvPairingSessionModel.fromJson(data);
  }

  @override
  Future<TvPairingStatusModel> getPairingStatus({
    required String sessionId,
    required String installationId,
  }) async {
    final response = await _dio.get(
      '/tv/pairing/sessions/$sessionId',
      options: Options(headers: {'X-TV-Installation-ID': installationId}),
    );
    final body = response.data as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>;
    return TvPairingStatusModel.fromJson(data);
  }

  @override
  Future<Response<dynamic>> getSnapshot({
    required String deviceToken,
    String? etag,
  }) async {
    final headers = <String, dynamic>{'Authorization': 'Bearer $deviceToken'};
    if (etag != null && etag.trim().isNotEmpty) {
      headers['If-None-Match'] = etag.trim();
    }

    return await _dio.get(
      '/tv/snapshot',
      options: Options(
        headers: headers,
        validateStatus: (status) =>
            status != null &&
            ((status >= 200 && status < 300) || status == 304),
      ),
    );
  }

  @override
  Future<void> unpairCurrent({required String deviceToken}) async {
    await _dio.delete(
      '/tv/devices/current',
      options: Options(headers: {'Authorization': 'Bearer $deviceToken'}),
    );
  }
}
