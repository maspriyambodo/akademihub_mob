import 'package:akademihub_mob/core/api/api_client.dart';
import 'package:akademihub_mob/core/config/app_config.dart';
import 'package:akademihub_mob/core/config/tenant_config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('applies tenant URL and restores fixed fallback', () {
    final client = ApiClient(const FlutterSecureStorage());
    const tenant = TenantConfig(
      identifier: 'school',
      name: 'School',
      apiBaseUrl: 'https://school.akademihub.id/api/v1/',
      wsHost: 'school.akademihub.id',
      wsAppKey: 'key',
    );

    client.applyTenant(tenant);
    expect(client.dio.options.baseUrl, 'https://school.akademihub.id/api/v1');

    client.applyTenant(null);
    expect(client.dio.options.baseUrl, AppConfig.apiBaseUrl);
  });
}
