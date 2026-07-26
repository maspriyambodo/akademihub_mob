import '../../../../core/error/result.dart';
import '../entities/tugas_siswa_entity.dart';
import '../repositories/tugas_repository.dart';

class GetPengumpulanListUseCase {
  final TugasRepository _repository;
  const GetPengumpulanListUseCase(this._repository);

  Future<Result<List<TugasSiswaEntity>>> call() =>
      _repository.getPengumpulanList();
}

class GetPengumpulanByTugasUseCase {
  final TugasRepository _repository;
  const GetPengumpulanByTugasUseCase(this._repository);

  Future<Result<List<TugasSiswaEntity>>> call(int tugasId) =>
      _repository.getPengumpulanByTugas(tugasId);
}

class GetPengumpulanBySiswaUseCase {
  final TugasRepository _repository;
  const GetPengumpulanBySiswaUseCase(this._repository);

  Future<Result<List<TugasSiswaEntity>>> call(int siswaId) =>
      _repository.getPengumpulanBySiswa(siswaId);
}
