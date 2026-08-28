import '../../../../core/error/result.dart';
import '../entities/absensi_siswa_entity.dart';
import '../repositories/absensi_repository.dart';
import '../entities/attendance_location.dart';

class GetAbsensiSiswaListUseCase {
  final AbsensiRepository _repository;
  const GetAbsensiSiswaListUseCase(this._repository);

  Future<Result<List<AbsensiSiswaEntity>>> call(int siswaId) =>
      _repository.getAbsensiSiswaList(siswaId);
}

class CheckInAbsensiUseCase {
  final AbsensiRepository _repository;
  const CheckInAbsensiUseCase(this._repository);

  Future<Result<void>> call(AttendanceLocation location) =>
      _repository.checkIn(location);
}

class CheckOutAbsensiUseCase {
  final AbsensiRepository _repository;
  const CheckOutAbsensiUseCase(this._repository);

  Future<Result<void>> call(AttendanceLocation location) =>
      _repository.checkOut(location);
}

class GetCurrentAbsensiUseCase {
  final AbsensiRepository _repository;
  const GetCurrentAbsensiUseCase(this._repository);

  Future<Result<AbsensiSiswaEntity?>> call() =>
      _repository.getCurrentAttendance();
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
