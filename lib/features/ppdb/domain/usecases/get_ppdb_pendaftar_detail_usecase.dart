import '../../../../core/error/result.dart';
import '../entities/ppdb_pendaftar_entity.dart';
import '../repositories/ppdb_repository.dart';

class GetPpdbPendaftarDetailUseCase {
  final PpdbRepository _repository;
  const GetPpdbPendaftarDetailUseCase(this._repository);

  Future<Result<PpdbPendaftarEntity>> call(int id) =>
      _repository.getPendaftarDetail(id);
}
