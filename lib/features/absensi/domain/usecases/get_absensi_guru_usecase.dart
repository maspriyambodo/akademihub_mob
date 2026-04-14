import '../../../../core/error/result.dart';
import '../entities/absensi_guru_entity.dart';
import '../repositories/absensi_repository.dart';

class GetAbsensiGuruListUseCase {
  final AbsensiRepository _repository;
  const GetAbsensiGuruListUseCase(this._repository);

  Future<Result<List<AbsensiGuruEntity>>> call(int guruId) =>
      _repository.getAbsensiGuruList(guruId);
}
