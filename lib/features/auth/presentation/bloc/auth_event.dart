part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

class AuthLoginRequested extends AuthEvent {
  final String identifier;
  final String password;

  AuthLoginRequested({required this.identifier, required this.password});

  @override
  List<Object?> get props => [identifier];
}

class AuthLogoutRequested extends AuthEvent {}
