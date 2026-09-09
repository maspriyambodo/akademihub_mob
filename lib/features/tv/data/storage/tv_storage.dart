import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/config/app_config.dart';

class TvStorage {
  final FlutterSecureStorage _secureStorage;
  final SharedPreferences _prefs;

  static const String keyInstallationId = 'tv_installation_id';
  static const String keyDeviceToken = 'tv_device_token';
  static const String keyDeviceId = 'tv_device_id';
  static const String keyDeviceMode = 'tv_device_mode';
  static const String keyTokenOrigin = 'tv_token_origin';

  static const String keySnapshotJson = 'tv_snapshot_json_v1';
  static const String keySnapshotCachedAt = 'tv_snapshot_cached_at_v1';
  static const String keySnapshotEtag = 'tv_snapshot_etag_v1';

  static const Duration maxCacheAge = Duration(hours: 24);

  const TvStorage({
    required FlutterSecureStorage secureStorage,
    required SharedPreferences prefs,
  })  : _secureStorage = secureStorage,
        _prefs = prefs;

  static String generateUuidV4() {
    final random = Random.secure();
    final values = List<int>.generate(16, (_) => random.nextInt(256));
    values[6] = (values[6] & 0x0f) | 0x40;
    values[8] = (values[8] & 0x3f) | 0x80;
    final hex = values.map((b) => b.toRadixString(16).padLeft(2, '0')).toList();
    return '${hex.sublist(0, 4).join()}-${hex.sublist(4, 6).join()}-${hex.sublist(6, 8).join()}-${hex.sublist(8, 10).join()}-${hex.sublist(10, 16).join()}';
  }

  Future<String> getOrCreateInstallationId() async {
    final existing = await _secureStorage.read(key: keyInstallationId);
    if (existing != null && existing.trim().isNotEmpty) {
      return existing.trim();
    }
    final newId = generateUuidV4();
    await _secureStorage.write(key: keyInstallationId, value: newId);
    return newId;
  }

  Future<void> saveDeviceCredentials({
    required String token,
    required int deviceId,
    required String mode,
    required String origin,
  }) async {
    await _secureStorage.write(key: keyDeviceToken, value: token);
    await _secureStorage.write(key: keyDeviceId, value: deviceId.toString());
    await _secureStorage.write(key: keyDeviceMode, value: mode);
    await _secureStorage.write(key: keyTokenOrigin, value: origin);
  }

  Future<String?> getDeviceToken() async {
    await _validateOrigin();
    return _secureStorage.read(key: keyDeviceToken);
  }

  Future<int?> getDeviceId() async {
    final str = await _secureStorage.read(key: keyDeviceId);
    return str != null ? int.tryParse(str) : null;
  }

  Future<String?> getDeviceMode() => _secureStorage.read(key: keyDeviceMode);

  Future<String?> getTokenOrigin() => _secureStorage.read(key: keyTokenOrigin);

  Future<bool> hasDeviceToken() async {
    final token = await getDeviceToken();
    return token != null && token.trim().isNotEmpty;
  }

  Future<void> clearSession() async {
    await _secureStorage.delete(key: keyDeviceToken);
    await _secureStorage.delete(key: keyDeviceId);
    await _secureStorage.delete(key: keyDeviceMode);
    await _secureStorage.delete(key: keyTokenOrigin);
    await clearCache();
  }

  Future<void> saveCachedSnapshot({
    required String jsonString,
    String? etag,
  }) async {
    await _prefs.setString(keySnapshotJson, jsonString);
    await _prefs.setString(
      keySnapshotCachedAt,
      DateTime.now().toUtc().toIso8601String(),
    );
    if (etag != null) {
      await _prefs.setString(keySnapshotEtag, etag);
    } else {
      await _prefs.remove(keySnapshotEtag);
    }
  }

  String? getCachedSnapshotJson() {
    final cachedAtStr = _prefs.getString(keySnapshotCachedAt);
    if (cachedAtStr == null) return null;
    final cachedAt = DateTime.tryParse(cachedAtStr)?.toUtc();
    if (cachedAt == null) return null;

    if (DateTime.now().toUtc().difference(cachedAt) > maxCacheAge) {
      clearCache();
      return null;
    }
    return _prefs.getString(keySnapshotJson);
  }

  String? getCachedEtag() {
    if (getCachedSnapshotJson() == null) return null;
    return _prefs.getString(keySnapshotEtag);
  }

  Future<void> clearCache() async {
    await _prefs.remove(keySnapshotJson);
    await _prefs.remove(keySnapshotCachedAt);
    await _prefs.remove(keySnapshotEtag);
  }

  Future<void> _validateOrigin() async {
    final savedOrigin = await _secureStorage.read(key: keyTokenOrigin);
    if (savedOrigin == null) return;
    final currentOrigin = AppConfig.extractOrigin(AppConfig.apiBaseUrl);
    if (currentOrigin != null && savedOrigin != currentOrigin) {
      await clearSession();
    }
  }
}
