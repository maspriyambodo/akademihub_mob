import '../../../../core/error/result.dart';
import '../entities/log_akses_materi_entity.dart';
import '../repositories/materi_repository.dart';

/// Statistik pembaca untuk satu materi (view guru/admin).
class GetStatistikMateriUseCase {
  final MateriRepository _repository;
  const GetStatistikMateriUseCase(this._repository);

  Future<Result<MateriStatistikEntity>> call(int materiId) async {
    final hasil = await _repository.getLogAksesByMateri(materiId);
    if (hasil.isFailure) return fail(hasil.requireFailure);
    return success(MateriStatistikEntity.fromLogs(hasil.requireData));
  }
}

/// Riwayat baca satu siswa.
class GetLogAksesBySiswaUseCase {
  final MateriRepository _repository;
  const GetLogAksesBySiswaUseCase(this._repository);

  Future<Result<List<LogAksesMateriEntity>>> call(int siswaId) =>
      _repository.getLogAksesBySiswa(siswaId);
}

/// Catat siswa membuka materi. Dipakai secara *fire-and-forget* oleh halaman
/// detail — kegagalannya sengaja tidak ditampilkan ke pengguna.
class CatatAksesMateriUseCase {
  final MateriRepository _repository;
  const CatatAksesMateriUseCase(this._repository);

  Future<Result<LogAksesMateriEntity>> call({
    required int materiId,
    required int siswaId,
    required int kelasId,
  }) => _repository.catatAkses(
    materiId: materiId,
    siswaId: siswaId,
    kelasId: kelasId,
  );
}

/// Perbarui durasi baca saat siswa meninggalkan halaman detail.
class UpdateDurasiBacaUseCase {
  final MateriRepository _repository;
  const UpdateDurasiBacaUseCase(this._repository);

  Future<Result<LogAksesMateriEntity>> call({
    required int logId,
    required int durasiDetik,
  }) => _repository.updateDurasi(logId: logId, durasiDetik: durasiDetik);
}
