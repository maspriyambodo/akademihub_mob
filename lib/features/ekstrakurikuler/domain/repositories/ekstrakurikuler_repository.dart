import '../../../../core/error/result.dart';
import '../entities/ekstrakurikuler_entity.dart';
import '../entities/ekstrakurikuler_statistik_entity.dart';
import '../entities/pendaftaran_ekskul_entity.dart';

abstract class EkstrakurikulerRepository {
  /// `GET /ekstrakurikuler/aktif` — hanya ekskul berstatus `aktif`.
  Future<Result<List<EkstrakurikulerEntity>>> getEkstrakurikulerAktif();

  /// `GET /ekstrakurikuler` — daftar terpaginasi (semua status).
  Future<Result<List<EkstrakurikulerEntity>>> getEkstrakurikulerList({
    String? status,
    String? search,
  });

  /// `GET /ekstrakurikuler/{id}`.
  Future<Result<EkstrakurikulerEntity>> getEkstrakurikulerDetail(int id);

  /// `GET /ekstrakurikuler/{id}/statistik`.
  Future<Result<EkstrakurikulerStatistikEntity>> getStatistik(int id);

  /// `GET /ekstrakurikuler/pembina/{pembinaGuruId}` — ekskul yang dibina guru.
  Future<Result<List<EkstrakurikulerEntity>>> getByPembina(int pembinaGuruId);

  /// `GET /ekstrakurikuler/pendaftaran/ekstrakurikuler/{id}` — peserta aktif.
  Future<Result<List<PendaftaranEkskulEntity>>> getPesertaByEkstrakurikuler(
    int ekstrakurikulerId,
  );

  /// `GET /ekstrakurikuler/pendaftaran/siswa/{siswaId}` — keanggotaan aktif.
  Future<Result<List<PendaftaranEkskulEntity>>> getPendaftaranBySiswa(
    int siswaId,
  );

  /// `GET /ekstrakurikuler/pendaftaran/siswa/{siswaId}/riwayat` — semua status.
  Future<Result<List<PendaftaranEkskulEntity>>> getRiwayatBySiswa(int siswaId);

  /// `GET /ekstrakurikuler/pendaftaran` — daftar umum, sudah difilter backend
  /// sesuai sesi (dipakai untuk role wali yang tidak punya id siswa).
  Future<Result<List<PendaftaranEkskulEntity>>> getPendaftaranList({
    int? siswaId,
    int? ekstrakurikulerId,
    String? status,
  });

  /// `POST /ekstrakurikuler/pendaftaran` — permission
  /// `ekstrakurikuler.pendaftaran.manage`.
  Future<Result<PendaftaranEkskulEntity>> daftarEkstrakurikuler({
    required int ekstrakurikulerId,
    required int siswaId,
  });

  /// `POST /ekstrakurikuler/pendaftaran/check-status` — true bila siswa sudah
  /// terdaftar (status `aktif`) pada ekskul tersebut.
  Future<Result<bool>> checkStatusPendaftaran({
    required int siswaId,
    required int ekstrakurikulerId,
  });

  /// `POST /ekstrakurikuler/pendaftaran/{id}/keluar` — permission
  /// `ekstrakurikuler.pendaftaran.manage`.
  Future<Result<PendaftaranEkskulEntity>> keluarEkstrakurikuler(
    int pendaftaranId,
  );
}
