import '../../../../core/error/result.dart';
import '../entities/tmb_jawaban_entity.dart';
import '../repositories/tmb_repository.dart';

class KirimTmbJawabanUseCase {
  final TmbRepository _repository;
  const KirimTmbJawabanUseCase(this._repository);

  Future<Result<TmbJawabanEntity>> call({
    required int pesertaId,
    required int pertanyaanId,
    int? opsiId,
    String? jawabanTeks,
  }) => _repository.kirimJawaban(
    pesertaId: pesertaId,
    pertanyaanId: pertanyaanId,
    opsiId: opsiId,
    jawabanTeks: jawabanTeks,
  );
}
