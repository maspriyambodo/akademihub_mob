import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/tenant_config.dart';

class TenantStorage {
  final SharedPreferences _prefs;

  static const String _tenantKey = 'active_tenant';

  const TenantStorage(this._prefs);

  Future<void> saveTenant(TenantConfig tenant) async {
    await _prefs.setString(_tenantKey, jsonEncode(tenant.toJson()));
  }

  TenantConfig? getSavedTenant() {
    final raw = _prefs.getString(_tenantKey);
    if (raw == null) return null;
    try {
      return TenantConfig.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearTenant() => _prefs.remove(_tenantKey);

  bool get hasSavedTenant => _prefs.containsKey(_tenantKey);
}
