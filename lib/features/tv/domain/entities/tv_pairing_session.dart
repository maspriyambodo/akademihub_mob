import 'package:equatable/equatable.dart';

class TvPairingSession extends Equatable {
  final String sessionId;
  final String userCode;
  final String verificationUrl;
  final DateTime expiresAt;
  final Duration pollInterval;

  const TvPairingSession({
    required this.sessionId,
    required this.userCode,
    required this.verificationUrl,
    required this.expiresAt,
    required this.pollInterval,
  });

  bool get isExpired => DateTime.now().toUtc().isAfter(expiresAt);

  @override
  List<Object?> get props => [
    sessionId,
    userCode,
    verificationUrl,
    expiresAt,
    pollInterval,
  ];
}

enum TvPairingState { pending, approved, denied, expired }

class TvPairingStatus extends Equatable {
  final TvPairingState state;
  final DateTime? expiresAt;
  final String? deviceToken;
  final int? deviceId;
  final String? deviceName;
  final String? deviceMode;

  const TvPairingStatus({
    required this.state,
    this.expiresAt,
    this.deviceToken,
    this.deviceId,
    this.deviceName,
    this.deviceMode,
  });

  @override
  List<Object?> get props => [
    state,
    expiresAt,
    deviceToken,
    deviceId,
    deviceName,
    deviceMode,
  ];
}
