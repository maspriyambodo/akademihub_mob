import 'package:equatable/equatable.dart';
import '../../domain/entities/tv_pairing_session.dart';

abstract class TvAuthState extends Equatable {
  const TvAuthState();

  @override
  List<Object?> get props => [];
}

class TvAuthInitial extends TvAuthState {
  const TvAuthInitial();
}

class TvAuthChecking extends TvAuthState {
  const TvAuthChecking();
}

class TvAuthPaired extends TvAuthState {
  final int? deviceId;
  final String? deviceMode;

  const TvAuthPaired({this.deviceId, this.deviceMode});

  @override
  List<Object?> get props => [deviceId, deviceMode];
}

class TvPairingLoading extends TvAuthState {
  const TvPairingLoading();
}

class TvPairingPending extends TvAuthState {
  final TvPairingSession session;
  final int attempt;

  const TvPairingPending({
    required this.session,
    this.attempt = 0,
  });

  @override
  List<Object?> get props => [session, attempt];
}

class TvPairingDenied extends TvAuthState {
  final String message;

  const TvPairingDenied([this.message = 'Permintaan pairing ditolak oleh administrator']);

  @override
  List<Object?> get props => [message];
}

class TvPairingExpired extends TvAuthState {
  final TvPairingSession? session;

  const TvPairingExpired({this.session});

  @override
  List<Object?> get props => [session];
}

class TvAuthFailure extends TvAuthState {
  final String message;

  const TvAuthFailure({required this.message});

  @override
  List<Object?> get props => [message];
}
