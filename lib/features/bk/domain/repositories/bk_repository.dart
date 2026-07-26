import '../../../../core/error/result.dart';
import '../entities/bk_hasil_entity.dart';
import '../entities/bk_jenis_entity.dart';
import '../entities/bk_kasus_entity.dart';
import '../entities/bk_sesi_entity.dart';
import '../entities/bk_siswa_ringkas_entity.dart';
import '../entities/bk_tindakan_entity.dart';

abstract class BkRepository {
  /// Daftar kasus BK. Backend memfilter otomatis per sesi login:
  /// siswa → kasus miliknya, guru/guru BK → kasus yang ia tangani,
  /// wali → kasus anak-anaknya, admin → semua.
  Future<Result<List<BkKasusEntity>>> getKasusList();

  /// Kasus BK milik satu siswa (`/bk/kasus/siswa/{siswaId}`).
  Future<Result<List<BkKasusEntity>>> getKasusBySiswa(int siswaId);

  Future<Result<List<BkSesiEntity>>> getSesiByKasus(int kasusId);

  Future<Result<List<BkHasilEntity>>> getHasilByKasus(int kasusId);

  Future<Result<List<BkTindakanEntity>>> getTindakanByKasus(int kasusId);

  Future<Result<List<BkJenisEntity>>> getJenisList();

  /// Cari siswa (untuk form kasus baru; butuh permission `siswa.view`).
  Future<Result<List<BkSiswaRingkasEntity>>> searchSiswa(String query);

  Future<Result<BkKasusEntity>> createKasus({
    required int siswaId,
    required int guruId,
    required int jenisId,
    required String tanggal,
    required String keterangan,
  });

  Future<Result<BkSesiEntity>> createSesi({
    required int kasusId,
    required String tanggal,
    required int metode,
    required String catatan,
  });

  Future<Result<BkHasilEntity>> createHasil({
    required int kasusId,
    required String hasil,
    required String rekomendasi,
  });

  Future<Result<BkTindakanEntity>> createTindakan({
    required int kasusId,
    required String deskripsi,
  });
}
