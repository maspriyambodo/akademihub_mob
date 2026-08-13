import 'package:akademihub_mob/core/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppConfig.normalizeApiBaseUrl', () {
    test('normalizes approved AkademiHub tenant URL', () {
      expect(
        AppConfig.normalizeApiBaseUrl(
          ' HTTPS://School.AkademiHub.ID/api/v1/// ',
          allowDevelopmentHosts: false,
        ),
        'https://school.akademihub.id/api/v1',
      );
    });

    test('allows localhost only for development', () {
      expect(
        AppConfig.normalizeApiBaseUrl(
          'http://localhost:8002/api/v1/',
          allowDevelopmentHosts: true,
        ),
        'http://localhost:8002/api/v1',
      );
      expect(
        AppConfig.normalizeApiBaseUrl(
          'http://localhost:8002/api/v1',
          allowDevelopmentHosts: false,
        ),
        AppConfig.apiBaseUrl,
      );
    });

    test('rejects insecure, deceptive, and arbitrary production endpoints', () {
      for (final url in [
        'http://school.akademihub.id/api/v1',
        'https://akademihub.id.evil.test/api/v1',
        'https://user@school.akademihub.id/api/v1',
        'https://school.akademihub.id:8443/api/v1',
        'https://192.168.1.10/api/v1',
      ]) {
        expect(
          AppConfig.normalizeApiBaseUrl(url, allowDevelopmentHosts: false),
          AppConfig.apiBaseUrl,
        );
      }
    });
  });
}
