import '../../../../core/error/result.dart';
import '../entities/ppdb_dokumen_entity.dart';
import '../repositories/ppdb_repository.dart';

class GetPpdbDokumenUseCase {
  final PpdbRepository _repository;
  const GetPpdbDokumenUseCase(this._repository);

  Future<Result<List<PpdbDokumenEntity>>> call(int pendaftarId) =>
      _repository.getDokumenByPendaftar(pendaftarId);
}
