import '../../../../core/error/result.dart';
import '../entities/bk_siswa_ringkas_entity.dart';
import '../repositories/bk_repository.dart';

class SearchBkSiswaUseCase {
  final BkRepository _repository;
  const SearchBkSiswaUseCase(this._repository);

  Future<Result<List<BkSiswaRingkasEntity>>> call(String query) =>
      _repository.searchSiswa(query);
}
