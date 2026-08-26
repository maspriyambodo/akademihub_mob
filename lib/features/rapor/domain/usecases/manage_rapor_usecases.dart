import '../../../../core/error/result.dart';
import '../entities/rapor_entity.dart';
import '../repositories/rapor_repository.dart';

class CreateRaporUseCase {
  final RaporRepository _repository;
  const CreateRaporUseCase(this._repository);

  Future<Result<RaporEntity>> call({
    required int siswaId,
    required int semester,
    String? catatanWali,
    int? sakit,
    int? izin,
    int? tanpaKeterangan,
    List<Map<String, dynamic>>? details,
  }) => _repository.createRapor(
    siswaId: siswaId,
    semester: semester,
    catatanWali: catatanWali,
    sakit: sakit,
    izin: izin,
    tanpaKeterangan: tanpaKeterangan,
    details: details,
  );
}

class UpdateRaporUseCase {
  final RaporRepository _repository;
  const UpdateRaporUseCase(this._repository);

  Future<Result<RaporEntity>> call({
    required int id,
    int? siswaId,
    int? semester,
    String? catatanWali,
    int? sakit,
    int? izin,
    int? tanpaKeterangan,
  }) => _repository.updateRapor(
    id: id,
    siswaId: siswaId,
    semester: semester,
    catatanWali: catatanWali,
    sakit: sakit,
    izin: izin,
    tanpaKeterangan: tanpaKeterangan,
  );
}

class DeleteRaporUseCase {
  final RaporRepository _repository;
  const DeleteRaporUseCase(this._repository);

  Future<Result<bool>> call(int id) => _repository.deleteRapor(id);
}
