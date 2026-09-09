import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/tv_pairing_session.dart';
import '../../domain/entities/tv_snapshot.dart';
import '../../domain/repositories/tv_repository.dart';
import '../datasources/tv_remote_datasource.dart';
import '../models/tv_snapshot_model.dart';
import '../storage/tv_storage.dart';

class TvRepositoryImpl implements TvRepository {
  final TvRemoteDataSource _remoteDataSource;
  final TvStorage _storage;

  const TvRepositoryImpl({
    required TvRemoteDataSource remoteDataSource,
    required TvStorage storage,
  })  : _remoteDataSource = remoteDataSource,
        _storage = storage;

  @override
  Future<Result<TvPairingSession>> createPairingSession() async {
    try {
      final installationId = await _storage.getOrCreateInstallationId();
      final session = await _remoteDataSource.createPairingSession(
        installationId: installationId,
        deviceName: 'Android TV',
        appVersion: '1.0.0+1',
      );
      return success(session);
    } on DioException catch (e) {
      return fail(_mapDioError(e));
    } catch (e) {
      return fail(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<TvPairingStatus>> getPairingStatus(String sessionId) async {
    try {
      final installationId = await _storage.getOrCreateInstallationId();
      final status = await _remoteDataSource.getPairingStatus(
        sessionId: sessionId,
        installationId: installationId,
      );

      if (status.state == TvPairingState.approved &&
          status.deviceToken != null &&
          status.deviceToken!.isNotEmpty) {
        await _storage.saveDeviceCredentials(
          token: status.deviceToken!,
          deviceId: status.deviceId ?? 0,
          mode: status.deviceMode ?? 'signage',
          origin: AppConfig.extractOrigin(AppConfig.apiBaseUrl) ?? '',
        );
      }

      return success(status);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return success(const TvPairingStatus(state: TvPairingState.expired));
      }
      return fail(_mapDioError(e));
    } catch (e) {
      return fail(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<TvSnapshotFetch>> getSnapshot({String? etag}) async {
    try {
      final token = await _storage.getDeviceToken();
      if (token == null || token.isEmpty) {
        return fail(const AuthFailure('Device token tidak ditemukan'));
      }

      final cachedEtag = etag ?? _storage.getCachedEtag();
      final response = await _remoteDataSource.getSnapshot(
        deviceToken: token,
        etag: cachedEtag,
      );

      if (response.statusCode == 304) {
        return success(const TvSnapshotNotModified());
      }

      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>;
      final snapshot = TvSnapshotModel.fromJson(data);

      final responseEtag = response.headers.value('etag');
      final jsonStr = jsonEncode(data);
      await _storage.saveCachedSnapshot(
        jsonString: jsonStr,
        etag: responseEtag,
      );

      return success(TvSnapshotModified(snapshot, etag: responseEtag));
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        await _storage.clearSession();
        return fail(const AuthFailure('Sesi TV berakhir atau ditolak'));
      }
      return fail(_mapDioError(e));
    } catch (e) {
      return fail(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<TvSnapshot?>> readCachedSnapshot() async {
    try {
      final cachedJson = _storage.getCachedSnapshotJson();
      if (cachedJson == null || cachedJson.isEmpty) {
        return success(null);
      }
      final decoded = jsonDecode(cachedJson) as Map<String, dynamic>;
      final snapshot = TvSnapshotModel.fromJson(decoded);
      return success(snapshot);
    } catch (e) {
      return success(null);
    }
  }

  @override
  Future<Result<void>> unpair() async {
    try {
      final token = await _storage.getDeviceToken();
      if (token != null && token.isNotEmpty) {
        try {
          await _remoteDataSource.unpairCurrent(deviceToken: token);
        } catch (_) {
          // Best effort remote unpair
        }
      }
      await _storage.clearSession();
      return success(null);
    } catch (e) {
      await _storage.clearSession();
      return success(null);
    }
  }

  @override
  Future<bool> hasDeviceToken() => _storage.hasDeviceToken();

  Failure _mapDioError(DioException e) {
    final status = e.response?.statusCode;
    if (status == 401 || status == 403) {
      return const AuthFailure('Autentikasi TV tidak valid');
    }
    if (status == 429) {
      final retryHeader = e.response?.headers.value('retry-after');
      final seconds = int.tryParse(retryHeader ?? '') ?? 5;
      return RateLimitFailure('Terlalu banyak permintaan', seconds);
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.connectionError) {
      return const NetworkFailure('Tidak dapat terhubung ke server');
    }
    return ServerFailure('Terjadi kesalahan server (${status ?? 'unknown'})');
  }
}
