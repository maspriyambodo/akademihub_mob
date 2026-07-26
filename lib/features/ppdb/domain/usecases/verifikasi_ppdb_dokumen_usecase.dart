import '../../../../core/error/result.dart';
import '../entities/ppdb_dokumen_entity.dart';
import '../repositories/ppdb_repository.dart';

class VerifikasiPpdbDokumenUseCase {
  final PpdbRepository _repository;
  const VerifikasiPpdbDokumenUseCase(this._repository);

  Future<Result<PpdbDokumenEntity>> call(int dokumenId, {String? catatan}) =>
      _repository.verifikasiDokumen(dokumenId, catatan: catatan);
}
