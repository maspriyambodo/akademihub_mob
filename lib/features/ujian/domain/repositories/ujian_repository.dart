import '../../../../core/error/result.dart';
import '../entities/kelas_option_entity.dart';
import '../entities/ranking_entity.dart';
import '../entities/ujian_entity.dart';
import '../entities/ujian_nilai_entity.dart';

abstract class UjianRepository {
  /// `GET /akademik/ujian/kelas/{kelasId}` — daftar ujian sebuah kelas.
  Future<Result<List<UjianEntity>>> getUjianByKelas(int kelasId);

  /// `GET /akademik/ujian/{id}/nilai` — info ujian + nilai seluruh siswa.
  Future<Result<UjianNilaiDetailEntity>> getNilaiUjian(int ujianId);

  /// `GET /akademik/ranking/kelas/{kelasId}` — papan peringkat kelas.
  Future<Result<List<RankingEntity>>> getRankingByKelas(int kelasId);

  /// `POST /akademik/ranking/generate` — generate ulang peringkat kelas.
  /// [semesterId] = id `mst_semester`, [tahunAjaranId] = id `mst_tahun_ajaran`.
  Future<Result<List<RankingEntity>>> generateRanking({
    required int kelasId,
    required int semesterId,
    required int tahunAjaranId,
  });

  /// `GET /akademik/ranking/kelas/{kelasId}/export` — unduh xlsx peringkat.
  /// Mengembalikan path file lokal.
  Future<Result<String>> exportRanking({
    required int kelasId,
    required int semesterId,
    required int tahunAjaranId,
  });

  /// `GET /kelas` — daftar kelas untuk pemilih kelas guru/admin.
  /// [waliGuruId] menyaring hanya kelas yang diampu guru tsb sebagai
  /// wali kelas (sesuai batasan `canAccessKelasId` backend untuk role guru).
  Future<Result<List<KelasOptionEntity>>> getKelasOptions({int? waliGuruId});
}
