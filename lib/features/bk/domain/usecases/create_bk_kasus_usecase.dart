import '../../../../core/error/result.dart';
import '../entities/bk_kasus_entity.dart';
import '../repositories/bk_repository.dart';

class CreateBkKasusUseCase {
  final BkRepository _repository;
  const CreateBkKasusUseCase(this._repository);

  Future<Result<BkKasusEntity>> call({
    required int siswaId,
    required int guruId,
    required int jenisId,
    required String tanggal,
    required String keterangan,
  }) => _repository.createKasus(
    siswaId: siswaId,
    guruId: guruId,
    jenisId: jenisId,
    tanggal: tanggal,
    keterangan: keterangan,
  );
}
