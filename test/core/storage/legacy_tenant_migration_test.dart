import 'package:akademihub_mob/core/config/app_config.dart';
import 'package:akademihub_mob/core/storage/legacy_tenant_migration.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('upgrade removes legacy tenant and its origin-bound session', () async {
    SharedPreferences.setMockInitialValues({legacyActiveTenantKey: '{}'});
    FlutterSecureStorage.setMockInitialValues({
      AppConfig.tokenKey: 'access',
      AppConfig.refreshTokenKey: 'refresh',
      AppConfig.tokenOriginKey: 'https://old-school.akademihub.id',
    });
    final preferences = await SharedPreferences.getInstance();
    const secureStorage = FlutterSecureStorage();

    await migrateLegacyTenantState(preferences, secureStorage);

    expect(preferences.containsKey(legacyActiveTenantKey), isFalse);
    expect(await secureStorage.read(key: AppConfig.tokenKey), isNull);
    expect(await secureStorage.read(key: AppConfig.refreshTokenKey), isNull);
    expect(await secureStorage.read(key: AppConfig.tokenOriginKey), isNull);
  });

  test('fresh install leaves gateway session untouched', () async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({
      AppConfig.tokenKey: 'access',
      AppConfig.tokenOriginKey: AppConfig.extractOrigin(AppConfig.apiBaseUrl)!,
    });
    final preferences = await SharedPreferences.getInstance();
    const secureStorage = FlutterSecureStorage();

    await migrateLegacyTenantState(preferences, secureStorage);

    expect(await secureStorage.read(key: AppConfig.tokenKey), 'access');
    expect(
      await secureStorage.read(key: AppConfig.tokenOriginKey),
      AppConfig.extractOrigin(AppConfig.apiBaseUrl),
    );
  });
}
