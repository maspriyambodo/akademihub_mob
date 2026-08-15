import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:akademihub_mob/core/config/app_config.dart';
import 'package:akademihub_mob/core/config/tenant_config.dart';
import 'package:akademihub_mob/core/storage/token_storage.dart';
import 'package:akademihub_mob/core/storage/tenant_storage.dart';
import 'package:akademihub_mob/features/auth/domain/entities/user_entity.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MOB-TENANT-01 - Tenant Origin Binding & State Isolation Test', () {
    late TokenStorage tokenStorage;
    late TenantStorage tenantStorage;

    setUp(() async {
      FlutterSecureStorage.setMockInitialValues({});
      SharedPreferences.setMockInitialValues({});
      const secureStorage = FlutterSecureStorage();
      final prefs = await SharedPreferences.getInstance();

      tokenStorage = const TokenStorage(secureStorage);
      tenantStorage = TenantStorage(prefs);
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

    test('TenantStorage clears tenant cache on tenant change or logout', () async {
      const tenant = TenantConfig(
        identifier: 'sekolah-a',
        name: 'SMA N 1',
        apiBaseUrl: 'https://sekolahA.api.akademihub.id/api/v1',
        wsHost: 'sekolahA.api.akademihub.id',
        wsAppKey: 'key_123',
      );

      await tenantStorage.saveTenant(tenant);
      expect(tenantStorage.hasSavedTenant, isTrue);
      expect(tenantStorage.getSavedTenant()?.identifier, equals('sekolah-a'));

      await tenantStorage.clearTenant();
      expect(tenantStorage.hasSavedTenant, isFalse);
      expect(tenantStorage.getSavedTenant(), isNull);
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