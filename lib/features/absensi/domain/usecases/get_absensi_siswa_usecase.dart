import '../../../../core/error/result.dart';
import '../entities/absensi_siswa_entity.dart';
import '../repositories/absensi_repository.dart';

class GetAbsensiSiswaListUseCase {
  final AbsensiRepository _repository;
  const GetAbsensiSiswaListUseCase(this._repository);

  Future<Result<List<AbsensiSiswaEntity>>> call(int siswaId) =>
      _repository.getAbsensiSiswaList(siswaId);
}

class GetAbsensiSiswaGeneralUseCase {
  final AbsensiRepository _repository;
  const GetAbsensiSiswaGeneralUseCase(this._repository);

  Future<Result<List<AbsensiSiswaEntity>>> call({
    String? tanggalFrom,
    String? tanggalTo,
  }) => _repository.getAbsensiSiswaGeneral(
    tanggalFrom: tanggalFrom,
    tanggalTo: tanggalTo,
  );
}
