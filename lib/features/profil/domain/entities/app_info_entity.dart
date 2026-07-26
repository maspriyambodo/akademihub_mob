import 'package:equatable/equatable.dart';

/// Identitas aplikasi untuk kartu "Tentang Aplikasi".
/// Diambil dari `package_info_plus`.
class AppInfoEntity extends Equatable {
  final String namaAplikasi;
  final String versi;
  final String buildNumber;
  final String packageName;

  const AppInfoEntity({
    required this.namaAplikasi,
    required this.versi,
    required this.buildNumber,
    required this.packageName,
  });

  /// Contoh: "1.0.0 (1)" — build number disembunyikan bila kosong.
  String get versiLengkap =>
      buildNumber.isEmpty ? versi : '$versi ($buildNumber)';

  @override
  List<Object?> get props => [namaAplikasi, versi, buildNumber, packageName];
}
