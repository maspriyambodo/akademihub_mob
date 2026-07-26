import '../../../../core/error/result.dart';
import '../entities/organisasi_entity.dart';
import '../repositories/organisasi_repository.dart';

class GetOrganisasiListUseCase {
  final OrganisasiRepository _repository;
  const GetOrganisasiListUseCase(this._repository);

  Future<Result<List<OrganisasiEntity>>> call({String? status}) =>
      _repository.getOrganisasiList(status: status);
}
