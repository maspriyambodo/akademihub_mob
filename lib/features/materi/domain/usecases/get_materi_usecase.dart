import '../../../../core/error/result.dart';
import '../entities/log_akses_materi_entity.dart';
import '../entities/materi_entity.dart';
import '../repositories/materi_repository.dart';

class GetMateriListUseCase {
  final MateriRepository _repository;
  const GetMateriListUseCase(this._repository);

  Future<Result<List<MateriEntity>>> call({int? status}) =>
      _repository.getMateriList(status: status);
}

class GetMateriDetailUseCase {
  final MateriRepository _repository;
  const GetMateriDetailUseCase(this._repository);

  Future<Result<MateriEntity>> call(int id) => _repository.getMateriDetail(id);
}

class GetMateriByGuruMapelUseCase {
  final MateriRepository _repository;
  const GetMateriByGuruMapelUseCase(this._repository);

  Future<Result<List<MateriEntity>>> call(int guruMapelId) =>
      _repository.getMateriByGuruMapel(guruMapelId);
}

class GetMateriPopulerUseCase {
  final MateriRepository _repository;
  const GetMateriPopulerUseCase(this._repository);

  Future<Result<List<MateriPopulerEntity>>> call({int limit = 5}) =>
      _repository.getMateriPopuler(limit: limit);
}
