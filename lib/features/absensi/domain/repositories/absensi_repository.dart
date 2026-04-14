import '../../../../core/error/result.dart';
import '../entities/absensi_siswa_entity.dart';
import '../entities/absensi_guru_entity.dart';

abstract class AbsensiRepository {
  /// Ambil semua absensi siswa berdasarkan siswaId (data lengkap, filter bulan dilakukan client-side)
  Future<Result<List<AbsensiSiswaEntity>>> getAbsensiSiswaList(int siswaId);

  /// Ambil semua absensi guru berdasarkan guruId
  Future<Result<List<AbsensiGuruEntity>>> getAbsensiGuruList(int guruId);

  /// Ambil absensi siswa umum (untuk role admin/wali) dengan filter tanggal
  Future<Result<List<AbsensiSiswaEntity>>> getAbsensiSiswaGeneral({
    String? tanggalFrom,
    String? tanggalTo,
  });
}
