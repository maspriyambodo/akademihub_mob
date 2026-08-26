import '../../../../core/error/result.dart';
import '../entities/rapor_detail_entity.dart';
import '../entities/rapor_entity.dart';

abstract class RaporRepository {
  /// Daftar rapor umum (role guru/admin/wali). Backend sudah memfilter
  /// visibilitas sesuai role. [search] mencari nama/NIS siswa, nama kelas,
  /// dan nama tahun ajaran.
  Future<Result<List<RaporEntity>>> getRaporList({String? search});

  /// Rapor milik satu siswa (role siswa).
  Future<Result<List<RaporEntity>>> getRaporBySiswa(int siswaId);

  /// Rincian rapor per mata pelajaran + catatan wali kelas.
  Future<Result<RaporDetailEntity>> getRaporDetail(int raporId);

  Future<Result<RaporEntity>> createRapor({
    required int siswaId,
    required int semester,
    String? catatanWali,
    int? sakit,
    int? izin,
    int? tanpaKeterangan,
    List<Map<String, dynamic>>? details,
  });

  Future<Result<RaporEntity>> updateRapor({
    required int id,
    int? siswaId,
    int? semester,
    String? catatanWali,
    int? sakit,
    int? izin,
    int? tanpaKeterangan,
  });

  Future<Result<bool>> deleteRapor(int id);

  /// Unduh berkas rapor (xlsx) milik satu siswa.
  /// Mengembalikan path file lokal yang siap dibuka.
  Future<Result<String>> exportRaporSiswa(int siswaId);
}
