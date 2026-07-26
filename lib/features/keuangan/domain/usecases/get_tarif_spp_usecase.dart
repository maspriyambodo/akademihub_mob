import '../../../../core/error/result.dart';
import '../entities/tarif_spp_entity.dart';
import '../repositories/keuangan_repository.dart';

class GetTarifSppListUseCase {
  final KeuanganRepository _repository;
  const GetTarifSppListUseCase(this._repository);

  Future<Result<List<TarifSppEntity>>> call({String? search}) =>
      _repository.getTarifList(search: search);
}

class GetTarifSppDetailUseCase {
  final KeuanganRepository _repository;
  const GetTarifSppDetailUseCase(this._repository);

  Future<Result<TarifSppEntity>> call(int id) => _repository.getTarifDetail(id);
}

class GetTarifSppByKelasUseCase {
  final KeuanganRepository _repository;
  const GetTarifSppByKelasUseCase(this._repository);

  Future<Result<TarifSppEntity>> call(int kelasId, {int? tahunAjaranId}) =>
      _repository.getTarifByKelas(kelasId, tahunAjaranId: tahunAjaranId);
}
