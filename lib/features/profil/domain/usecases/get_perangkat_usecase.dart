import '../../../../core/error/result.dart';
import '../entities/perangkat_entity.dart';
import '../repositories/profil_repository.dart';

class GetPerangkatUserUseCase {
  final ProfilRepository _repository;
  const GetPerangkatUserUseCase(this._repository);

  Future<Result<List<PerangkatEntity>>> call(int userId) =>
      _repository.getPerangkatUser(userId);
}
