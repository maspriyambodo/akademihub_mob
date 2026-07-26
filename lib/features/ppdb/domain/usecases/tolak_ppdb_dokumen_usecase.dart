import '../../../../core/error/result.dart';
import '../entities/ppdb_dokumen_entity.dart';
import '../repositories/ppdb_repository.dart';

class TolakPpdbDokumenUseCase {
  final PpdbRepository _repository;
  const TolakPpdbDokumenUseCase(this._repository);

  /// `catatan` wajib — validasi backend `['required', 'string']`.
  Future<Result<PpdbDokumenEntity>> call(
    int dokumenId, {
    required String catatan,
  }) => _repository.tolakDokumen(dokumenId, catatan: catatan);
}
