import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Tidak ada koneksi internet']);
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Terjadi kesalahan server']);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Sesi telah berakhir']);
}

class ValidationFailure extends Failure {
  final Map<String, List<String>>? errors;
  const ValidationFailure(super.message, {this.errors});

  @override
  List<Object?> get props => [message, errors];
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Data tidak ditemukan']);
}
