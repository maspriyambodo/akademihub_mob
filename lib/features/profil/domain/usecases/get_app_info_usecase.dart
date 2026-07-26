import '../../../../core/error/result.dart';
import '../entities/app_info_entity.dart';
import '../repositories/profil_repository.dart';

class GetAppInfoUseCase {
  final ProfilRepository _repository;
  const GetAppInfoUseCase(this._repository);

  Future<Result<AppInfoEntity>> call() => _repository.getAppInfo();
}
