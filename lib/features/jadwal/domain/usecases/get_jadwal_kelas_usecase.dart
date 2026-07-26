import '../../../../core/error/result.dart';
import '../entities/jadwal_pelajaran_entity.dart';
import '../repositories/jadwal_repository.dart';

/// Ambil seluruh jadwal satu kelas (semua hari sekaligus).
/// Filter per hari dilakukan di client agar pindah tab tidak memicu request.
class GetJadwalKelasUseCase {
  final JadwalRepository _repository;
  const GetJadwalKelasUseCase(this._repository);

  Future<Result<List<JadwalPelajaranEntity>>> call(int kelasId) =>
      _repository.getJadwalByKelas(kelasId);
}

/// Ambil jadwal satu kelas untuk satu hari tertentu ('MON'..'SUN').
class GetJadwalKelasHariUseCase {
  final JadwalRepository _repository;
  const GetJadwalKelasHariUseCase(this._repository);

  Future<Result<List<JadwalPelajaranEntity>>> call(
    int kelasId,
    String hari,
  ) => _repository.getJadwalByKelasHari(kelasId, hari);
}
