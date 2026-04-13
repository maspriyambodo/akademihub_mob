import '../../../../core/error/result.dart';
import '../entities/tenant_entity.dart';
import '../repositories/tenant_repository.dart';

class ResolveTenantUseCase {
  final TenantRepository _repository;
  const ResolveTenantUseCase(this._repository);

  Future<Result<TenantEntity>> call(String identifier) =>
      _repository.resolveTenant(identifier.trim().toLowerCase());
}

class ListTenantsUseCase {
  final TenantRepository _repository;
  const ListTenantsUseCase(this._repository);

  Future<Result<List<TenantEntity>>> call({String? query}) =>
      _repository.listTenants(query: query);
}
