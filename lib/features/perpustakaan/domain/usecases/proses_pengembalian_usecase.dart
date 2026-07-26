import '../../../../core/error/result.dart';
import '../entities/peminjaman_buku_entity.dart';
import '../repositories/perpustakaan_repository.dart';

class ProsesPengembalianUseCase {
  final PerpustakaanRepository _repository;
  const ProsesPengembalianUseCase(this._repository);

  Future<Result<PeminjamanBukuEntity>> call(int peminjamanId) =>
      _repository.prosesPengembalian(peminjamanId);
}
