import 'package:dio/dio.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<Map<String, dynamic>> login(String username, String password);
  Future<Map<String, dynamic>> loginGoogle({
    String? idToken,
    String? serverAuthCode,
  });
  Future<void> logout();
  Future<UserModel> getCurrentUser();
  Future<void> registerFcmToken(String token);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio _dio;

  const AuthRemoteDataSourceImpl(this._dio);

  @override
  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await _dio.post(
      '/auth/login',
      data: {'username': username, 'password': password},
    );
    // Backend wraps payload in {"success":true,"data":{...}}
    final body = response.data as Map<String, dynamic>;
    return Map<String, dynamic>.from(body['data'] as Map<String, dynamic>);
  }

  @override
  Future<Map<String, dynamic>> loginGoogle({
    String? idToken,
    String? serverAuthCode,
  }) async {
    final payload = <String, dynamic>{};
    if (idToken != null) payload['id_token'] = idToken;
    if (serverAuthCode != null) payload['code'] = serverAuthCode;

    final response = await _dio.post('/auth/google', data: payload);
    final body = response.data as Map<String, dynamic>;
    return Map<String, dynamic>.from(body['data'] as Map<String, dynamic>);
  }

  @override
  Future<void> logout() async {
    await _dio.post('/auth/logout');
  }

  @override
  Future<UserModel> getCurrentUser() async {
    final response = await _dio.get('/auth/me');
    return UserModel.fromJson(response.data['data'] ?? response.data);
  }

  @override
  Future<void> registerFcmToken(String token) async {
    await _dio.post('/fcm/token', data: {'token': token});
  }
}
