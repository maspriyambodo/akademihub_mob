import '../../../../core/error/result.dart';
import '../entities/tenant_entity.dart';

abstract class TenantRepository {
  /// Resolve sekolah berdasarkan kode/subdomain yang diinput user
  Future<Result<TenantEntity>> resolveTenant(String identifier);

  /// Ambil daftar sekolah yang populer/terdaftar (opsional, untuk dropdown)
  Future<Result<List<TenantEntity>>> listTenants({String? query});
}
