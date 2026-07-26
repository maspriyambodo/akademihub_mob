import '../../../../core/error/result.dart';
import '../entities/rapor_entity.dart';
import '../repositories/rapor_repository.dart';

class GetRaporListUseCase {
  final RaporRepository _repository;
  const GetRaporListUseCase(this._repository);

  Future<Result<List<RaporEntity>>> call({String? search}) =>
      _repository.getRaporList(search: search);
}

class GetRaporBySiswaUseCase {
  final RaporRepository _repository;
  const GetRaporBySiswaUseCase(this._repository);

  Future<Result<List<RaporEntity>>> call(int siswaId) =>
      _repository.getRaporBySiswa(siswaId);
}
