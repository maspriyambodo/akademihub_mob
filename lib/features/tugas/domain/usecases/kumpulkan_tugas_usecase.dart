import '../../../../core/error/result.dart';
import '../entities/tugas_siswa_entity.dart';
import '../repositories/tugas_repository.dart';

class KumpulkanTugasUseCase {
  final TugasRepository _repository;
  const KumpulkanTugasUseCase(this._repository);

  Future<Result<TugasSiswaEntity>> call({
    required int siswaId,
    required int tugasId,
    String? jawaban,
    String? fileJawaban,
  }) => _repository.kumpulkanTugas(
    siswaId: siswaId,
    tugasId: tugasId,
    jawaban: jawaban,
    fileJawaban: fileJawaban,
  );
}
