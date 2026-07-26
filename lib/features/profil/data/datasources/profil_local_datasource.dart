import 'dart:convert';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/config/tenant_config.dart';
import '../models/app_info_model.dart';
import '../models/sekolah_model.dart';

abstract class ProfilLocalDataSource {
  /// Tenant (sekolah) yang tersimpan di perangkat, null bila belum pernah
  /// dipilih atau datanya rusak.
  Future<SekolahModel?> getSekolahTersimpan();

  Future<AppInfoModel> getAppInfo();
}

class ProfilLocalDataSourceImpl implements ProfilLocalDataSource {
  /// Key yang dipakai `TenantStorage` (`lib/core/storage/tenant_storage.dart`).
  /// Nilainya disalin karena konstanta di sana bersifat privat — fitur ini
  /// hanya MEMBACA, tidak pernah menulis ke key tersebut.
  static const String _tenantKey = 'active_tenant';

  const ProfilLocalDataSourceImpl();

  @override
  Future<SekolahModel?> getSekolahTersimpan() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_tenantKey);
      if (raw == null || raw.isEmpty) return null;

      final tenant = TenantConfig.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
      if (tenant.name.trim().isEmpty) return null;

      return SekolahModel.fromTenant(
        namaSekolah: tenant.name,
        logoPath: tenant.logoUrl,
      );
    } catch (_) {
      // Data tenant rusak / plugin belum siap → anggap tidak ada.
      return null;
    }
  }

  @override
  Future<AppInfoModel> getAppInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final nama = info.appName.trim().isEmpty ? 'AkademiHub' : info.appName;
      return AppInfoModel(
        namaAplikasi: nama,
        versi: info.version,
        buildNumber: info.buildNumber,
        packageName: info.packageName,
      );
    } catch (_) {
      return const AppInfoModel(
        namaAplikasi: 'AkademiHub',
        versi: '-',
        buildNumber: '',
        packageName: '',
      );
    }
  }
}
