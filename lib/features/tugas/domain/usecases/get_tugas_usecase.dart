import '../../../../core/error/result.dart';
import '../entities/tugas_entity.dart';
import '../repositories/tugas_repository.dart';

class GetTugasListUseCase {
  final TugasRepository _repository;
  const GetTugasListUseCase(this._repository);

  Future<Result<List<TugasEntity>>> call({int? status, String? search}) =>
      _repository.getTugasList(status: status, search: search);
}

class GetTugasDetailUseCase {
  final TugasRepository _repository;
  const GetTugasDetailUseCase(this._repository);

  Future<Result<TugasEntity>> call(int id) => _repository.getTugasDetail(id);
}

class GetTugasByKelasUseCase {
  final TugasRepository _repository;
  const GetTugasByKelasUseCase(this._repository);

  Future<Result<List<TugasEntity>>> call(int kelasId) =>
      _repository.getTugasByKelas(kelasId);
}

class GetTugasByGuruMapelUseCase {
  final TugasRepository _repository;
  const GetTugasByGuruMapelUseCase(this._repository);

  Future<Result<List<TugasEntity>>> call(int guruMapelId) =>
      _repository.getTugasByGuruMapel(guruMapelId);
}
