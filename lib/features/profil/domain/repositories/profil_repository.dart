import '../../../../core/error/result.dart';
import '../entities/app_info_entity.dart';
import '../entities/perangkat_entity.dart';
import '../entities/sekolah_entity.dart';

abstract class ProfilRepository {
  /// Ambil info sekolah dari API. Butuh permission `sekolah.view`.
  ///
  /// Urutan percobaan: [id] → [uuid] → daftar `/sekolah` yang dicocokkan
  /// dengan [nama] (nama tenant yang tersimpan di perangkat).
  Future<Result<SekolahEntity>> getSekolahAktif({
    int? id,
    String? uuid,
    String? nama,
  });

  /// Info sekolah dari tenant yang tersimpan di perangkat (tanpa jaringan).
  /// Dipakai sebagai fallback untuk role tanpa permission `sekolah.view`.
  Future<Result<SekolahEntity?>> getSekolahTersimpan();

  /// Daftar perangkat login user. Butuh permission `users.view`.
  Future<Result<List<PerangkatEntity>>> getPerangkatUser(int userId);

  /// Nama & versi aplikasi (package_info_plus).
  Future<Result<AppInfoEntity>> getAppInfo();
}
