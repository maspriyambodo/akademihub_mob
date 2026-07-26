import '../../../../core/error/result.dart';
import '../entities/ekstrakurikuler_entity.dart';
import '../entities/ekstrakurikuler_statistik_entity.dart';
import '../repositories/ekstrakurikuler_repository.dart';

class GetEkstrakurikulerAktifUseCase {
  final EkstrakurikulerRepository _repository;
  const GetEkstrakurikulerAktifUseCase(this._repository);

  Future<Result<List<EkstrakurikulerEntity>>> call() =>
      _repository.getEkstrakurikulerAktif();
}

class GetEkstrakurikulerListUseCase {
  final EkstrakurikulerRepository _repository;
  const GetEkstrakurikulerListUseCase(this._repository);

  Future<Result<List<EkstrakurikulerEntity>>> call({
    String? status,
    String? search,
  }) => _repository.getEkstrakurikulerList(status: status, search: search);
}

class GetEkstrakurikulerDetailUseCase {
  final EkstrakurikulerRepository _repository;
  const GetEkstrakurikulerDetailUseCase(this._repository);

  Future<Result<EkstrakurikulerEntity>> call(int id) =>
      _repository.getEkstrakurikulerDetail(id);
}

class GetEkstrakurikulerStatistikUseCase {
  final EkstrakurikulerRepository _repository;
  const GetEkstrakurikulerStatistikUseCase(this._repository);

  Future<Result<EkstrakurikulerStatistikEntity>> call(int id) =>
      _repository.getStatistik(id);
}

class GetEkstrakurikulerByPembinaUseCase {
  final EkstrakurikulerRepository _repository;
  const GetEkstrakurikulerByPembinaUseCase(this._repository);

  Future<Result<List<EkstrakurikulerEntity>>> call(int pembinaGuruId) =>
      _repository.getByPembina(pembinaGuruId);
}
