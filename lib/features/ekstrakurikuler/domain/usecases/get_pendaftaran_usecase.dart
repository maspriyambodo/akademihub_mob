import '../../../../core/error/result.dart';
import '../entities/pendaftaran_ekskul_entity.dart';
import '../repositories/ekstrakurikuler_repository.dart';

class GetPesertaEkstrakurikulerUseCase {
  final EkstrakurikulerRepository _repository;
  const GetPesertaEkstrakurikulerUseCase(this._repository);

  Future<Result<List<PendaftaranEkskulEntity>>> call(int ekstrakurikulerId) =>
      _repository.getPesertaByEkstrakurikuler(ekstrakurikulerId);
}

class GetPendaftaranSiswaUseCase {
  final EkstrakurikulerRepository _repository;
  const GetPendaftaranSiswaUseCase(this._repository);

  Future<Result<List<PendaftaranEkskulEntity>>> call(int siswaId) =>
      _repository.getPendaftaranBySiswa(siswaId);
}

class GetRiwayatPendaftaranSiswaUseCase {
  final EkstrakurikulerRepository _repository;
  const GetRiwayatPendaftaranSiswaUseCase(this._repository);

  Future<Result<List<PendaftaranEkskulEntity>>> call(int siswaId) =>
      _repository.getRiwayatBySiswa(siswaId);
}

class GetPendaftaranListUseCase {
  final EkstrakurikulerRepository _repository;
  const GetPendaftaranListUseCase(this._repository);

  Future<Result<List<PendaftaranEkskulEntity>>> call({
    int? siswaId,
    int? ekstrakurikulerId,
    String? status,
  }) => _repository.getPendaftaranList(
    siswaId: siswaId,
    ekstrakurikulerId: ekstrakurikulerId,
    status: status,
  );
}

class CheckStatusPendaftaranUseCase {
  final EkstrakurikulerRepository _repository;
  const CheckStatusPendaftaranUseCase(this._repository);

  Future<Result<bool>> call({
    required int siswaId,
    required int ekstrakurikulerId,
  }) => _repository.checkStatusPendaftaran(
    siswaId: siswaId,
    ekstrakurikulerId: ekstrakurikulerId,
  );
}
