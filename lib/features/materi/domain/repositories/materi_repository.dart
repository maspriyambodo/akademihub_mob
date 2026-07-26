import '../../../../core/error/result.dart';
import '../entities/log_akses_materi_entity.dart';
import '../entities/materi_entity.dart';

abstract class MateriRepository {
  /// Daftar materi umum (`GET /akademik/materi`).
  /// Backend otomatis membatasi hasil untuk role siswa/wali sesuai guru-mapel
  /// yang dapat mereka akses.
  Future<Result<List<MateriEntity>>> getMateriList({int? status});

  /// Detail satu materi (`GET /akademik/materi/{id}`).
  Future<Result<MateriEntity>> getMateriDetail(int id);

  /// Materi milik satu guru-mapel (`GET /akademik/materi/guru-mapel/{id}`).
  Future<Result<List<MateriEntity>>> getMateriByGuruMapel(int guruMapelId);

  /// Materi terpopuler berdasarkan jumlah akses.
  Future<Result<List<MateriPopulerEntity>>> getMateriPopuler({int limit});

  /// Seluruh log akses untuk satu materi (dipakai statistik guru/admin).
  Future<Result<List<LogAksesMateriEntity>>> getLogAksesByMateri(int materiId);

  /// Riwayat baca satu siswa.
  Future<Result<List<LogAksesMateriEntity>>> getLogAksesBySiswa(int siswaId);

  /// Catat siswa membuka materi (`POST /akademik/log-akses-materi`).
  /// Mengembalikan log yang baru dibuat — `id`-nya dipakai untuk update durasi.
  Future<Result<LogAksesMateriEntity>> catatAkses({
    required int materiId,
    required int siswaId,
    required int kelasId,
  });

  /// Perbarui durasi baca (`PUT /akademik/log-akses-materi/{id}/durasi`).
  Future<Result<LogAksesMateriEntity>> updateDurasi({
    required int logId,
    required int durasiDetik,
  });
}
