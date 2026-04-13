import 'package:dio/dio.dart';

abstract class AppException implements Exception {
  final String message;
  const AppException(this.message);
}

class NetworkException extends AppException {
  const NetworkException([super.message = 'Tidak ada koneksi internet']);
}

class ServerException extends AppException {
  final int? statusCode;
  const ServerException(super.message, {this.statusCode});
}

class AuthException extends AppException {
  const AuthException([
    super.message = 'Sesi telah berakhir, silakan login kembali',
  ]);
}

class ValidationException extends AppException {
  final Map<String, List<String>>? errors;
  const ValidationException(super.message, {this.errors});
}

class NotFoundException extends AppException {
  const NotFoundException([super.message = 'Data tidak ditemukan']);
}

AppException mapDioException(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return const NetworkException('Koneksi timeout, coba lagi');
    case DioExceptionType.connectionError:
      return const NetworkException();
    case DioExceptionType.badResponse:
      final status = e.response?.statusCode;
      final data = e.response?.data;
      final message = data is Map
          ? (data['message'] ?? 'Terjadi kesalahan')
          : 'Terjadi kesalahan';

      if (status == 401) return const AuthException();
      if (status == 404) return NotFoundException(message.toString());
      if (status == 422) {
        final errors = data is Map
            ? data['errors'] as Map<String, dynamic>?
            : null;
        return ValidationException(
          message.toString(),
          errors: errors?.map((k, v) => MapEntry(k, List<String>.from(v))),
        );
      }
      return ServerException(message.toString(), statusCode: status);
    default:
      return const ServerException('Terjadi kesalahan tidak terduga');
  }
}
