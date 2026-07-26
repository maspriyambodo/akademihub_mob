import '../../../../core/error/result.dart';
import '../entities/ppdb_pendaftar_entity.dart';
import '../repositories/ppdb_repository.dart';

class UbahStatusPpdbPendaftarUseCase {
  final PpdbRepository _repository;
  const UbahStatusPpdbPendaftarUseCase(this._repository);

  /// [aksi]: `verify` (→ terverifikasi), `accept` (→ diterima),
  /// `reject` (→ ditolak). Endpoint POST tanpa body.
  Future<Result<PpdbPendaftarEntity>> call(
    int pendaftarId, {
    required String aksi,
  }) => _repository.ubahStatusPendaftar(pendaftarId, aksi: aksi);
}
