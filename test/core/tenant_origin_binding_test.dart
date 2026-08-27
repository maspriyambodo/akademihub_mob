import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:akademihub_mob/core/config/app_config.dart';
import 'package:akademihub_mob/core/storage/token_storage.dart';
import 'package:akademihub_mob/features/auth/domain/entities/user_entity.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MOB-TENANT-01 - Tenant Origin Binding & State Isolation Test', () {
    late TokenStorage tokenStorage;

    setUp(() async {
      FlutterSecureStorage.setMockInitialValues({});
      const secureStorage = FlutterSecureStorage();

      tokenStorage = const TokenStorage(secureStorage);
    });

    test('AppConfig.extractOrigin extracts scheme and host correctly', () {
      expect(
        AppConfig.extractOrigin('https://sekolahA.api.akademihub.id/api/v1'),
        equals('https://sekolaha.api.akademihub.id'),
      );
      expect(
        AppConfig.extractOrigin('http://127.0.0.1:8002/api/v1'),
        equals('http://127.0.0.1:8002'),
      );
      expect(AppConfig.extractOrigin('invalid_url'), isNull);
    });

    test('TokenStorage saves and clears token origin', () async {
      await tokenStorage.saveTokens(
        accessToken: 'access_123',
        refreshToken: 'refresh_456',
        origin: 'https://sekolahA.api.akademihub.id',
      );

      final token = await tokenStorage.getAccessToken();
      final refreshToken = await tokenStorage.getRefreshToken();
      final origin = await tokenStorage.getTokenOrigin();

      expect(token, equals('access_123'));
      expect(refreshToken, equals('refresh_456'));
      expect(origin, equals('https://sekolahA.api.akademihub.id'));

      await tokenStorage.clearTokens();

      expect(await tokenStorage.getAccessToken(), isNull);
      expect(await tokenStorage.getRefreshToken(), isNull);
      expect(await tokenStorage.getTokenOrigin(), isNull);
    });

    test('UserEntity correctly identifies superadmin role restriction', () {
      const superAdminUser = UserEntity(
        id: 1,
        name: 'Super Admin',
        email: 'superadmin@akademihub.id',
        role: 'superadmin',
      );

      const regularUser = UserEntity(
        id: 2,
        name: 'Guru A',
        email: 'guru@sekolah.sch.id',
        role: 'guru',
      );

      expect(superAdminUser.isSuperAdmin, isTrue);
      expect(regularUser.isSuperAdmin, isFalse);
    });
  });
}
