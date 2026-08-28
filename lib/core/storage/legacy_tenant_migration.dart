import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';

const legacyActiveTenantKey = 'active_tenant';

Future<void> migrateLegacyTenantState(
  SharedPreferences preferences,
  FlutterSecureStorage secureStorage,
) async {
  if (!preferences.containsKey(legacyActiveTenantKey)) return;

  await preferences.remove(legacyActiveTenantKey);
  await Future.wait([
    secureStorage.delete(key: AppConfig.tokenKey),
    secureStorage.delete(key: AppConfig.refreshTokenKey),
    secureStorage.delete(key: AppConfig.tokenOriginKey),
  ]);
}
