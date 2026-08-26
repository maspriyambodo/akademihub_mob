import '../../../../core/error/result.dart';
import '../entities/nilai_entity.dart';

abstract class NilaiRepository {
  /// Semua nilai milik satu siswa — `GET /akademik/nilai/siswa/{siswaId}`.
  Future<Result<List<NilaiEntity>>> getNilaiBySiswa(int siswaId);

  /// Semua nilai pada satu ujian — `GET /akademik/nilai/ujian/{ujianId}`.
  Future<Result<List<NilaiEntity>>> getNilaiByUjian(int ujianId);

  /// Daftar nilai umum terpaginasi — `GET /akademik/nilai`.
  /// Backend sudah membatasi data sesuai role yang login.
  Future<Result<List<NilaiEntity>>> getNilaiGeneral({
    int? siswaId,
    int? ujianId,
    int perPage = 100,
  });

  /// Rata-rata nilai siswa — `GET /akademik/nilai/siswa/{siswaId}/rata-rata`.
  /// Response bukan list, melainkan `{ "rata_rata": 85.5 }` (bisa null).
  Future<Result<double?>> getRataRataSiswa(int siswaId);

  Future<Result<NilaiEntity>> createNilai({
    required int siswaId,
    required int ujianId,
    required double nilai,
    String? keterangan,
  });

  Future<Result<NilaiEntity>> updateNilai({
    required int id,
    int? siswaId,
    int? ujianId,
    double? nilai,
    String? keterangan,
  });

  Future<Result<bool>> deleteNilai(int id);
}
