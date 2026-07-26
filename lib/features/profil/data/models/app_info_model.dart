import '../../domain/entities/app_info_entity.dart';

class AppInfoModel {
  final String namaAplikasi;
  final String versi;
  final String buildNumber;
  final String packageName;

  const AppInfoModel({
    required this.namaAplikasi,
    required this.versi,
    required this.buildNumber,
    required this.packageName,
  });

  AppInfoEntity toEntity() => AppInfoEntity(
    namaAplikasi: namaAplikasi,
    versi: versi,
    buildNumber: buildNumber,
    packageName: packageName,
  );
}
