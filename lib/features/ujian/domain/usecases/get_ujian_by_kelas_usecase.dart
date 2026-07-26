import '../../../../core/error/result.dart';
import '../entities/ujian_entity.dart';
import '../repositories/ujian_repository.dart';

class GetUjianByKelasUseCase {
  final UjianRepository _repository;
  const GetUjianByKelasUseCase(this._repository);

  Future<Result<List<UjianEntity>>> call(int kelasId) =>
      _repository.getUjianByKelas(kelasId);
}
