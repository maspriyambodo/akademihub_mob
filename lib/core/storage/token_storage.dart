import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';

class TokenStorage {
  final FlutterSecureStorage _storage;

  const TokenStorage(this._storage);

  Future<String?> getAccessToken() => _storage.read(key: AppConfig.tokenKey);

  Future<String?> getRefreshToken() =>
      _storage.read(key: AppConfig.refreshTokenKey);

  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    await _storage.write(key: AppConfig.tokenKey, value: accessToken);
    if (refreshToken != null) {
      await _storage.write(key: AppConfig.refreshTokenKey, value: refreshToken);
    }
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: AppConfig.tokenKey);
    await _storage.delete(key: AppConfig.refreshTokenKey);
  }

  Future<bool> hasValidToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
}
