import 'package:package_info_plus/package_info_plus.dart';

import '../models/app_info_model.dart';

abstract class ProfilLocalDataSource {
  Future<AppInfoModel> getAppInfo();
}

class ProfilLocalDataSourceImpl implements ProfilLocalDataSource {
  const ProfilLocalDataSourceImpl();

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
