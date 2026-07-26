import '../../../../core/error/result.dart';
import '../entities/organisasi_detail_entity.dart';
import '../repositories/organisasi_repository.dart';

class GetOrganisasiDetailUseCase {
  final OrganisasiRepository _repository;
  const GetOrganisasiDetailUseCase(this._repository);

  Future<Result<OrganisasiDetailEntity>> call(int id) =>
      _repository.getOrganisasiDetail(id);
}
