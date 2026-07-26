import '../../../../core/error/result.dart';
import '../entities/jadwal_pelajaran_entity.dart';
import '../repositories/jadwal_repository.dart';

/// Ambil daftar jadwal umum (endpoint index) dengan filter opsional.
class GetJadwalListUseCase {
  final JadwalRepository _repository;
  const GetJadwalListUseCase(this._repository);

  Future<Result<List<JadwalPelajaranEntity>>> call({
    int? kelasId,
    String? hari,
  }) => _repository.getJadwalList(kelasId: kelasId, hari: hari);
}
