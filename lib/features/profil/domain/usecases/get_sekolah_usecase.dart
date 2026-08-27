import '../../../../core/error/result.dart';
import '../entities/sekolah_entity.dart';
import '../repositories/profil_repository.dart';

class GetSekolahAktifUseCase {
  final ProfilRepository _repository;
  const GetSekolahAktifUseCase(this._repository);

  Future<Result<SekolahEntity>> call({int? id, String? uuid, String? nama}) =>
      _repository.getSekolahAktif(id: id, uuid: uuid, nama: nama);
}
