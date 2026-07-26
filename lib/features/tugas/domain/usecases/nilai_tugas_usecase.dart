import '../../../../core/error/result.dart';
import '../entities/tugas_siswa_entity.dart';
import '../repositories/tugas_repository.dart';

class NilaiTugasUseCase {
  final TugasRepository _repository;
  const NilaiTugasUseCase(this._repository);

  Future<Result<TugasSiswaEntity>> call({
    required int pengumpulanId,
    required double nilai,
    String? catatanGuru,
  }) => _repository.nilaiTugas(
    pengumpulanId: pengumpulanId,
    nilai: nilai,
    catatanGuru: catatanGuru,
  );
}
