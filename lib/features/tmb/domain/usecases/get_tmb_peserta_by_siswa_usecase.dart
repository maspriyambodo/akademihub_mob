import '../../../../core/error/result.dart';
import '../entities/tmb_peserta_entity.dart';
import '../repositories/tmb_repository.dart';

class GetTmbPesertaBySiswaUseCase {
  final TmbRepository _repository;
  const GetTmbPesertaBySiswaUseCase(this._repository);

  Future<Result<List<TmbPesertaEntity>>> call(int siswaId) =>
      _repository.getPesertaBySiswa(siswaId);
}
