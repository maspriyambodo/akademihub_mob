import '../../../../core/error/result.dart';
import '../entities/peminjaman_buku_entity.dart';
import '../repositories/perpustakaan_repository.dart';

class CreatePeminjamanUseCase {
  final PerpustakaanRepository _repository;
  const CreatePeminjamanUseCase(this._repository);

  /// [tanggalPinjam] & [tanggalJatuhTempo] memakai format `YYYY-MM-DD`.
  /// Backend mewajibkan `tanggal_jatuh_tempo` dan harus SETELAH
  /// `tanggal_pinjam` (`CreatePeminjamanBukuRequest`).
  Future<Result<PeminjamanBukuEntity>> call({
    required int siswaId,
    required int bukuId,
    String? tanggalPinjam,
    required String tanggalJatuhTempo,
  }) => _repository.createPeminjaman(
    siswaId: siswaId,
    bukuId: bukuId,
    tanggalPinjam: tanggalPinjam,
    tanggalJatuhTempo: tanggalJatuhTempo,
  );
}
