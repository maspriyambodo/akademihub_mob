import '../../../../core/error/result.dart';
import '../entities/ppdb_hasil_seleksi_entity.dart';
import '../repositories/ppdb_repository.dart';

class GetPpdbHasilSeleksiUseCase {
  final PpdbRepository _repository;
  const GetPpdbHasilSeleksiUseCase(this._repository);

  Future<Result<List<PpdbHasilSeleksiEntity>>> call(int gelombangId) =>
      _repository.getHasilSeleksi(gelombangId);
}
