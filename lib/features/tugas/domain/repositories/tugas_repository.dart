import '../../../../core/error/result.dart';
import '../entities/tugas_entity.dart';
import '../entities/tugas_siswa_entity.dart';

abstract class TugasRepository {
  /// Daftar tugas umum (terpaginasi backend) — dipakai admin/guru/fallback.
  Future<Result<List<TugasEntity>>> getTugasList({int? status, String? search});

  /// Detail satu tugas.
  Future<Result<TugasEntity>> getTugasDetail(int id);

  /// Tugas aktif untuk satu kelas (dipakai siswa/wali).
  Future<Result<List<TugasEntity>>> getTugasByKelas(int kelasId);

  /// Tugas milik satu guru-mapel (dipakai guru bila id guru-mapel diketahui).
  Future<Result<List<TugasEntity>>> getTugasByGuruMapel(int guruMapelId);

  Future<Result<TugasEntity>> createTugas({
    required int guruMapelId,
    required int kelasId,
    required String judul,
    required String tenggatWaktu,
    String? deskripsi,
    String? fileLampiran,
    int? status,
  });

  Future<Result<TugasEntity>> updateTugas({
    required int id,
    int? guruMapelId,
    int? kelasId,
    String? judul,
    String? deskripsi,
    String? fileLampiran,
    String? tenggatWaktu,
    int? status,
  });

  Future<Result<bool>> deleteTugas(int id);

  /// Daftar pengumpulan umum (otomatis difilter backend sesuai role).
  Future<Result<List<TugasSiswaEntity>>> getPengumpulanList();

  /// Daftar pengumpulan untuk satu tugas (view guru).
  Future<Result<List<TugasSiswaEntity>>> getPengumpulanByTugas(int tugasId);

  /// Daftar pengumpulan milik satu siswa.
  Future<Result<List<TugasSiswaEntity>>> getPengumpulanBySiswa(int siswaId);

  /// Siswa mengumpulkan / memperbarui pengumpulan tugas.
  Future<Result<TugasSiswaEntity>> kumpulkanTugas({
    required int siswaId,
    required int tugasId,
    String? jawaban,
    String? fileJawaban,
  });

  /// Guru memberi nilai pada satu pengumpulan.
  Future<Result<TugasSiswaEntity>> nilaiTugas({
    required int pengumpulanId,
    required double nilai,
    String? catatanGuru,
  });
}
