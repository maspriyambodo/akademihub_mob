import '../../../../core/error/result.dart';
import '../entities/nilai_entity.dart';
import '../repositories/nilai_repository.dart';

class CreateNilaiUseCase {
  final NilaiRepository _repository;
  const CreateNilaiUseCase(this._repository);

  Future<Result<NilaiEntity>> call({
    required int siswaId,
    required int ujianId,
    required double nilai,
    String? keterangan,
  }) => _repository.createNilai(
    siswaId: siswaId,
    ujianId: ujianId,
    nilai: nilai,
    keterangan: keterangan,
  );
}
