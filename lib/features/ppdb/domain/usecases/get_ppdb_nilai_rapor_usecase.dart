import '../../../../core/error/result.dart';
import '../repositories/ppdb_repository.dart';

class GetPpdbNilaiRaporUseCase {
  final PpdbRepository _repository;
  const GetPpdbNilaiRaporUseCase(this._repository);

  Future<Result<PpdbNilaiRaporBundle>> call(int pendaftarId) =>
      _repository.getNilaiRapor(pendaftarId);
}
