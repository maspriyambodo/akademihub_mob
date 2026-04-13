import 'package:dio/dio.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<Map<String, dynamic>> login(String email, String password);
  Future<void> logout();
  Future<UserModel> getCurrentUser();
  Future<Map<String, dynamic>> refreshToken(String refreshToken);
  Future<void> registerFcmToken(String token);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio _dio;

  const AuthRemoteDataSourceImpl(this._dio);

  @override
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _dio.post(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    // Backend wraps payload in {"success":true,"data":{...}}
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
  Future<Map<String, dynamic>> refreshToken(String token) async {
    final response = await _dio.post(
      '/auth/refresh',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return Map<String, dynamic>.from(response.data);
  }

  @override
  Future<void> registerFcmToken(String token) async {
    await _dio.post('/fcm/token', data: {'token': token});
  }
}
