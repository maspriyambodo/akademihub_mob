import '../../../../core/error/result.dart';
import '../repositories/rapor_repository.dart';

/// Butuh permission `rapor.export` di sisi backend.
/// Mengembalikan path file lokal hasil unduhan.
class ExportRaporUseCase {
  final RaporRepository _repository;
  const ExportRaporUseCase(this._repository);

  Future<Result<String>> call(int siswaId) =>
      _repository.exportRaporSiswa(siswaId);
}
