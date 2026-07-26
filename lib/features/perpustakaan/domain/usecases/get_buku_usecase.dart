import '../../../../core/error/result.dart';
import '../entities/buku_entity.dart';
import '../entities/buku_riwayat_entity.dart';
import '../repositories/perpustakaan_repository.dart';

class GetBukuListUseCase {
  final PerpustakaanRepository _repository;
  const GetBukuListUseCase(this._repository);

  Future<Result<List<BukuEntity>>> call({int perPage = 200, String? search}) =>
      _repository.getBukuList(perPage: perPage, search: search);
}

class GetBukuAvailableUseCase {
  final PerpustakaanRepository _repository;
  const GetBukuAvailableUseCase(this._repository);

  Future<Result<List<BukuEntity>>> call() => _repository.getBukuAvailable();
}

class GetBukuDetailUseCase {
  final PerpustakaanRepository _repository;
  const GetBukuDetailUseCase(this._repository);

  Future<Result<BukuEntity>> call(int bukuId) =>
      _repository.getBukuDetail(bukuId);
}

class GetRiwayatBukuUseCase {
  final PerpustakaanRepository _repository;
  const GetRiwayatBukuUseCase(this._repository);

  Future<Result<BukuRiwayatEntity>> call(int bukuId) =>
      _repository.getRiwayatBuku(bukuId);
}
