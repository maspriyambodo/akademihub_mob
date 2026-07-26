import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../entities/ppdb_dokumen_entity.dart';
import '../entities/ppdb_gelombang_entity.dart';
import '../entities/ppdb_hasil_seleksi_entity.dart';
import '../entities/ppdb_nilai_rapor_entity.dart';
import '../entities/ppdb_pendaftar_entity.dart';
import '../entities/ppdb_statistik_entity.dart';

/// Failure khusus 403: user tidak punya permission `ppdb.*`.
///
/// `core/error/failures.dart` belum punya varian "forbidden" dan file core
/// tidak boleh disentuh dari fitur, jadi varian ini didefinisikan lokal
/// (pola yang sama dengan `KalenderAccessFailure`).
class PpdbAccessFailure extends Failure {
  const PpdbAccessFailure([
    super.message = 'Anda tidak memiliki izin untuk mengakses data PPDB.',
  ]);
}

/// Paket data nilai rapor satu pendaftar (daftar + statistik).
class PpdbNilaiRaporBundle {
  final List<PpdbNilaiRaporEntity> daftar;
  final PpdbNilaiStatistikEntity statistik;

  const PpdbNilaiRaporBundle({
    this.daftar = const [],
    this.statistik = PpdbNilaiStatistikEntity.kosong,
  });
}

abstract class PpdbRepository {
  Future<Result<List<PpdbGelombangEntity>>> getGelombangList();

  /// Daftar pendaftar. Filter `search`, `statusPendaftaran`, dan `gelombangId`
  /// diterapkan server-side (`PpdbPendaftaranService::getAllPendaftaran`).
  Future<Result<List<PpdbPendaftarEntity>>> getPendaftarList({
    String? search,
    String? statusPendaftaran,
    int? gelombangId,
  });

  Future<Result<PpdbPendaftarEntity>> getPendaftarDetail(int id);

  Future<Result<PpdbStatistikEntity>> getStatistik({
    required int sekolahId,
    int? gelombangId,
  });

  Future<Result<List<PpdbDokumenEntity>>> getDokumenByPendaftar(
    int pendaftarId,
  );

  Future<Result<PpdbNilaiRaporBundle>> getNilaiRapor(int pendaftarId);

  Future<Result<List<PpdbHasilSeleksiEntity>>> getHasilSeleksi(
    int gelombangId,
  );

  /// POST `/ppdb/dokumen/{id}/verify` — `catatan` opsional.
  Future<Result<PpdbDokumenEntity>> verifikasiDokumen(
    int dokumenId, {
    String? catatan,
  });

  /// POST `/ppdb/dokumen/{id}/reject` — `catatan` wajib.
  Future<Result<PpdbDokumenEntity>> tolakDokumen(
    int dokumenId, {
    required String catatan,
  });

  /// POST `/ppdb/pendaftaran/{id}/verify|accept|reject`.
  /// [aksi] harus salah satu dari: `verify`, `accept`, `reject`.
  Future<Result<PpdbPendaftarEntity>> ubahStatusPendaftar(
    int pendaftarId, {
    required String aksi,
  });
}
