import '../../../../core/error/result.dart';
import '../entities/nilai_entity.dart';
import '../repositories/nilai_repository.dart';

class GetNilaiGeneralUseCase {
  final NilaiRepository _repository;
  const GetNilaiGeneralUseCase(this._repository);

  Future<Result<List<NilaiEntity>>> call({
    int? siswaId,
    int? ujianId,
    int perPage = 100,
  }) => _repository.getNilaiGeneral(
    siswaId: siswaId,
    ujianId: ujianId,
    perPage: perPage,
  );
}

class GetNilaiUjianUseCase {
  final NilaiRepository _repository;
  const GetNilaiUjianUseCase(this._repository);

  Future<Result<List<NilaiEntity>>> call(int ujianId) =>
      _repository.getNilaiByUjian(ujianId);
}
