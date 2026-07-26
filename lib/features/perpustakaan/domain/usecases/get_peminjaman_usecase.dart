import '../../../../core/error/result.dart';
import '../entities/peminjaman_buku_entity.dart';
import '../repositories/perpustakaan_repository.dart';

class GetPeminjamanListUseCase {
  final PerpustakaanRepository _repository;
  const GetPeminjamanListUseCase(this._repository);

  Future<Result<List<PeminjamanBukuEntity>>> call({int perPage = 100}) =>
      _repository.getPeminjamanList(perPage: perPage);
}

class GetPeminjamanBySiswaUseCase {
  final PerpustakaanRepository _repository;
  const GetPeminjamanBySiswaUseCase(this._repository);

  Future<Result<List<PeminjamanBukuEntity>>> call(int siswaId) =>
      _repository.getPeminjamanBySiswa(siswaId);
}

class GetPeminjamanOverdueUseCase {
  final PerpustakaanRepository _repository;
  const GetPeminjamanOverdueUseCase(this._repository);

  Future<Result<List<PeminjamanBukuEntity>>> call() =>
      _repository.getPeminjamanOverdue();
}
