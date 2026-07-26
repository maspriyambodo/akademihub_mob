import '../../../../core/error/result.dart';
import '../entities/ujian_nilai_entity.dart';
import '../repositories/ujian_repository.dart';

class GetNilaiUjianUseCase {
  final UjianRepository _repository;
  const GetNilaiUjianUseCase(this._repository);

  Future<Result<UjianNilaiDetailEntity>> call(int ujianId) =>
      _repository.getNilaiUjian(ujianId);
}
