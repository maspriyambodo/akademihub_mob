import '../../../../core/error/result.dart';
import '../entities/jadwal_pelajaran_entity.dart';

abstract class JadwalRepository {
  /// Seluruh jadwal satu kelas (semua hari) — dipakai role siswa/wali.
  Future<Result<List<JadwalPelajaranEntity>>> getJadwalByKelas(int kelasId);

  /// Jadwal satu kelas untuk satu hari tertentu (kode 'MON'..'SUN').
  Future<Result<List<JadwalPelajaranEntity>>> getJadwalByKelasHari(
    int kelasId,
    String hari,
  );

  /// Daftar jadwal umum (index) dengan filter opsional — dipakai role
  /// admin, dan guru (hasilnya difilter per guru di sisi client).
  Future<Result<List<JadwalPelajaranEntity>>> getJadwalList({
    int? kelasId,
    String? hari,
  });
}
