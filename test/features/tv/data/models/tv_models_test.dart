import 'package:akademihub_mob/features/tv/data/models/tv_pairing_model.dart';
import 'package:akademihub_mob/features/tv/domain/entities/tv_pairing_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TvPairingSessionModel', () {
    test('fromJson parses valid payload and converts to UTC', () {
      final json = {
        'session_id': 'sess-1234',
        'user_code': 'AB7K9Q',
        'verification_url': 'https://app.akademihub.id/tv-pair',
        'expires_at': '2026-09-05T14:15:00Z',
        'poll_interval_seconds': 5,
      };

      final model = TvPairingSessionModel.fromJson(json);

      expect(model.sessionId, 'sess-1234');
      expect(model.userCode, 'AB7K9Q');
      expect(model.verificationUrl, 'https://app.akademihub.id/tv-pair');
      expect(model.expiresAt, DateTime.utc(2026, 9, 5, 14, 15, 0));
      expect(model.pollInterval, const Duration(seconds: 5));
    });

    test('fromJson clamps poll_interval_seconds to minimum 3 seconds', () {
      final json = {
        'session_id': 'sess-1234',
        'user_code': 'AB7K9Q',
        'verification_url': 'https://app.akademihub.id/tv-pair',
        'expires_at': '2026-09-05T14:15:00Z',
        'poll_interval_seconds': 1,
      };

      final model = TvPairingSessionModel.fromJson(json);
      expect(model.pollInterval, const Duration(seconds: 3));
    });

    test(
      'fromJson throws FormatException on missing or empty required fields',
      () {
        expect(
          () => TvPairingSessionModel.fromJson({
            'user_code': 'AB7K9Q',
            'verification_url': 'https://app.akademihub.id/tv-pair',
            'expires_at': '2026-09-05T14:15:00Z',
          }),
          throwsFormatException,
        );

        expect(
          () => TvPairingSessionModel.fromJson({
            'session_id': '',
            'user_code': 'AB7K9Q',
            'verification_url': 'https://app.akademihub.id/tv-pair',
            'expires_at': '2026-09-05T14:15:00Z',
          }),
          throwsFormatException,
        );
      },
    );
  });

  group('TvPairingStatusModel', () {
    test('fromJson parses pending status', () {
      final json = {'status': 'pending', 'expires_at': '2026-09-05T14:15:00Z'};

      final model = TvPairingStatusModel.fromJson(json);
      expect(model.state, TvPairingState.pending);
      expect(model.expiresAt, DateTime.utc(2026, 9, 5, 14, 15, 0));
      expect(model.deviceToken, isNull);
    });

    test('fromJson parses approved status with device information', () {
      final json = {
        'status': 'approved',
        'device_token': 'secret-device-token-123',
        'device': {'id': 42, 'name': 'TV Lobby Utama', 'mode': 'signage'},
      };

      final model = TvPairingStatusModel.fromJson(json);
      expect(model.state, TvPairingState.approved);
      expect(model.deviceToken, 'secret-device-token-123');
      expect(model.deviceId, 42);
      expect(model.deviceName, 'TV Lobby Utama');
      expect(model.deviceMode, 'signage');
    });

    test('fromJson parses denied and expired status', () {
      expect(
        TvPairingStatusModel.fromJson({'status': 'denied'}).state,
        TvPairingState.denied,
      );
      expect(
        TvPairingStatusModel.fromJson({'status': 'expired'}).state,
        TvPairingState.expired,
      );
    });

    test('fromJson throws FormatException on invalid status', () {
      expect(
        () => TvPairingStatusModel.fromJson({'status': 'unknown_status'}),
        throwsFormatException,
      );
    });
  });
}
