import '../../../../core/error/result.dart';
import '../entities/nilai_entity.dart';
import '../repositories/nilai_repository.dart';

class UpdateNilaiUseCase {
  final NilaiRepository _repository;
  const UpdateNilaiUseCase(this._repository);

  Future<Result<NilaiEntity>> call({
    required int id,
    int? siswaId,
    int? ujianId,
    double? nilai,
    String? keterangan,
  }) => _repository.updateNilai(
    id: id,
    siswaId: siswaId,
    ujianId: ujianId,
    nilai: nilai,
    keterangan: keterangan,
  );
}
