import '../../../../core/error/result.dart';
import '../entities/pendaftaran_ekskul_entity.dart';
import '../repositories/ekstrakurikuler_repository.dart';

class KeluarEkstrakurikulerUseCase {
  final EkstrakurikulerRepository _repository;
  const KeluarEkstrakurikulerUseCase(this._repository);

  Future<Result<PendaftaranEkskulEntity>> call(int pendaftaranId) =>
      _repository.keluarEkstrakurikuler(pendaftaranId);
}
