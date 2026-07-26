import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../entities/tmb_hasil_entity.dart';
import '../entities/tmb_jawaban_entity.dart';
import '../entities/tmb_pertanyaan_entity.dart';
import '../entities/tmb_peserta_entity.dart';
import '../entities/tmb_tes_entity.dart';

/// Failure khusus HTTP 403 (PermissionMiddleware) agar UI bisa menampilkan
/// tampilan "akses ditolak" alih-alih error server generik.
class TmbAccessFailure extends Failure {
  const TmbAccessFailure([
    super.message = 'Anda tidak memiliki izin mengakses tes minat bakat',
  ]);
}

abstract class TmbRepository {
  /// Semua tes (untuk admin/staf). `GET /akademik/tes-minat-bakat`.
  Future<Result<List<TmbTesEntity>>> getTesList();

  /// Tes yang punya peserta dari kelas tertentu.
  /// `GET /akademik/tes-minat-bakat/kelas/{kelasId}`.
  Future<Result<List<TmbTesEntity>>> getTesByKelas(int kelasId);

  /// Pertanyaan satu tes beserta opsinya.
  ///
  /// [viaTesDetail] = true memakai `GET /akademik/tes-minat-bakat/{id}`
  /// (relasi `pertanyaan.opsi` ikut termuat) — jalur untuk siswa yang tidak
  /// punya izin `tes-minat-bakat-pertanyaan.view`. Bila false memakai
  /// `GET /akademik/tes-minat-bakat-pertanyaan/tes/{tesId}`.
  Future<Result<List<TmbPertanyaanEntity>>> getPertanyaan(
    int tesId, {
    required bool viaTesDetail,
  });

  /// `GET /akademik/tes-minat-bakat-peserta/siswa/{siswaId}` — sudah memuat
  /// relasi `tes` dan `hasil.aspek`.
  Future<Result<List<TmbPesertaEntity>>> getPesertaBySiswa(int siswaId);

  /// `GET /akademik/tes-minat-bakat-peserta/tes/{tesId}` — sudah memuat
  /// relasi `siswa.kelas` dan `hasil.aspek`.
  Future<Result<List<TmbPesertaEntity>>> getPesertaByTes(int tesId);

  /// `POST /akademik/tes-minat-bakat-peserta` (`tes-minat-bakat-peserta.create`).
  Future<Result<TmbPesertaEntity>> daftarPeserta({
    required int tesId,
    required int siswaId,
  });

  /// `POST /akademik/tes-minat-bakat-peserta/{id}/mulai`.
  Future<Result<TmbPesertaEntity>> mulaiTes(int pesertaId);

  /// `POST /akademik/tes-minat-bakat-peserta/{id}/selesaikan` — backend
  /// menghitung skor per aspek dan mengembalikan peserta dgn `hasil.aspek`.
  Future<Result<TmbPesertaEntity>> selesaikanTes(int pesertaId);

  /// `POST /akademik/tes-minat-bakat-jawaban` — upsert per pertanyaan.
  Future<Result<TmbJawabanEntity>> kirimJawaban({
    required int pesertaId,
    required int pertanyaanId,
    int? opsiId,
    String? jawabanTeks,
  });

  /// Jawaban tersimpan milik satu peserta (untuk melanjutkan pengerjaan).
  /// `GET /akademik/tes-minat-bakat-jawaban?peserta_id={id}&per_page=all`.
  Future<Result<List<TmbJawabanEntity>>> getJawabanByPeserta(int pesertaId);

  /// `GET /akademik/tes-minat-bakat-hasil/peserta/{pesertaId}`.
  ///
  /// Catatan: untuk role siswa/wali endpoint ini error di backend (filter
  /// memakai kolom `mst_siswa_id` yang tidak ada); untuk mereka hasil diambil
  /// dari relasi `hasil` pada data peserta.
  Future<Result<List<TmbHasilEntity>>> getHasilByPeserta(int pesertaId);
}
