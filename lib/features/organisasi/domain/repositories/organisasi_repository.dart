import '../../../../core/error/result.dart';
import '../entities/organisasi_detail_entity.dart';
import '../entities/organisasi_entity.dart';

/// Kontrak repository modul Organisasi (read-only di mobile —
/// aksi kelola dilakukan admin lewat web).
abstract class OrganisasiRepository {
  /// Daftar organisasi. [status] opsional (`aktif`/`nonaktif`) diteruskan
  /// ke server; null = semua status.
  Future<Result<List<OrganisasiEntity>>> getOrganisasiList({String? status});

  /// Detail organisasi beserta struktur kepengurusan (anggota + jabatan).
  Future<Result<OrganisasiDetailEntity>> getOrganisasiDetail(int id);
}
