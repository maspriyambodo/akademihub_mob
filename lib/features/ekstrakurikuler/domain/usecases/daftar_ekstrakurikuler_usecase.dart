import '../../../../core/error/result.dart';
import '../entities/pendaftaran_ekskul_entity.dart';
import '../repositories/ekstrakurikuler_repository.dart';

class DaftarEkstrakurikulerUseCase {
  final EkstrakurikulerRepository _repository;
  const DaftarEkstrakurikulerUseCase(this._repository);

  Future<Result<PendaftaranEkskulEntity>> call({
    required int ekstrakurikulerId,
    required int siswaId,
  }) => _repository.daftarEkstrakurikuler(
    ekstrakurikulerId: ekstrakurikulerId,
    siswaId: siswaId,
  );
}
