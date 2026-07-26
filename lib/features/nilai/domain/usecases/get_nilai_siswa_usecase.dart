import '../../../../core/error/result.dart';
import '../entities/nilai_entity.dart';
import '../repositories/nilai_repository.dart';

class GetNilaiSiswaUseCase {
  final NilaiRepository _repository;
  const GetNilaiSiswaUseCase(this._repository);

  Future<Result<List<NilaiEntity>>> call(int siswaId) =>
      _repository.getNilaiBySiswa(siswaId);
}

class GetRataRataNilaiUseCase {
  final NilaiRepository _repository;
  const GetRataRataNilaiUseCase(this._repository);

  Future<Result<double?>> call(int siswaId) =>
      _repository.getRataRataSiswa(siswaId);
}
