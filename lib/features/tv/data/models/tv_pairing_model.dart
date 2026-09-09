import '../../domain/entities/tv_pairing_session.dart';

class TvPairingSessionModel extends TvPairingSession {
  const TvPairingSessionModel({
    required super.sessionId,
    required super.userCode,
    required super.verificationUrl,
    required super.expiresAt,
    required super.pollInterval,
  });

  factory TvPairingSessionModel.fromJson(Map<String, dynamic> json) {
    final sessionId = json['session_id'] as String?;
    final userCode = json['user_code'] as String?;
    final verificationUrl = json['verification_url'] as String?;
    final expiresAtStr = json['expires_at'] as String?;
    final pollSeconds = (json['poll_interval_seconds'] as num?)?.toInt() ?? 5;

    if (sessionId == null ||
        sessionId.isEmpty ||
        userCode == null ||
        userCode.isEmpty ||
        verificationUrl == null ||
        verificationUrl.isEmpty ||
        expiresAtStr == null) {
      throw const FormatException(
        'Invalid or missing fields in TvPairingSession',
      );
    }

    final expiresAt = DateTime.parse(expiresAtStr).toUtc();
    return TvPairingSessionModel(
      sessionId: sessionId,
      userCode: userCode,
      verificationUrl: verificationUrl,
      expiresAt: expiresAt,
      pollInterval: Duration(seconds: pollSeconds.clamp(3, 60)),
    );
  }
}

class TvPairingStatusModel extends TvPairingStatus {
  const TvPairingStatusModel({
    required super.state,
    super.expiresAt,
    super.deviceToken,
    super.deviceId,
    super.deviceName,
    super.deviceMode,
  });

  factory TvPairingStatusModel.fromJson(Map<String, dynamic> json) {
    final statusStr = (json['status'] as String?)?.toLowerCase();
    final state = switch (statusStr) {
      'pending' => TvPairingState.pending,
      'approved' => TvPairingState.approved,
      'denied' => TvPairingState.denied,
      'expired' => TvPairingState.expired,
      _ => throw FormatException('Invalid pairing status: $statusStr'),
    };

    final expiresAtStr = json['expires_at'] as String?;
    final expiresAt =
        expiresAtStr != null ? DateTime.parse(expiresAtStr).toUtc() : null;

    final deviceToken = json['device_token'] as String?;
    final deviceMap = json['device'] as Map<String, dynamic>?;

    return TvPairingStatusModel(
      state: state,
      expiresAt: expiresAt,
      deviceToken: deviceToken,
      deviceId: (deviceMap?['id'] as num?)?.toInt(),
      deviceName: deviceMap?['name'] as String?,
      deviceMode: deviceMap?['mode'] as String?,
    );
  }
}
