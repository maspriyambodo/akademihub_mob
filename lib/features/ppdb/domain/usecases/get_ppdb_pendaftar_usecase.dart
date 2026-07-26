import '../../../../core/error/result.dart';
import '../entities/ppdb_pendaftar_entity.dart';
import '../repositories/ppdb_repository.dart';

class GetPpdbPendaftarUseCase {
  final PpdbRepository _repository;
  const GetPpdbPendaftarUseCase(this._repository);

  Future<Result<List<PpdbPendaftarEntity>>> call({
    String? search,
    String? statusPendaftaran,
    int? gelombangId,
  }) => _repository.getPendaftarList(
    search: search,
    statusPendaftaran: statusPendaftaran,
    gelombangId: gelombangId,
  );
}
