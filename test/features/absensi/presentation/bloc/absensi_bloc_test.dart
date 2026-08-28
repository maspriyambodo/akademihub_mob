import 'package:akademihub_mob/core/error/result.dart' as result;
import 'package:akademihub_mob/core/error/failures.dart';
import 'package:akademihub_mob/features/absensi/domain/entities/absensi_guru_entity.dart';
import 'package:akademihub_mob/features/absensi/domain/entities/absensi_siswa_entity.dart';
import 'package:akademihub_mob/features/absensi/domain/repositories/absensi_repository.dart';
import 'package:akademihub_mob/features/absensi/domain/usecases/get_absensi_guru_usecase.dart';
import 'package:akademihub_mob/features/absensi/domain/usecases/get_absensi_siswa_usecase.dart';
import 'package:akademihub_mob/features/absensi/presentation/bloc/absensi_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:akademihub_mob/features/absensi/data/services/attendance_location_service.dart';
import 'package:akademihub_mob/features/absensi/domain/entities/attendance_location.dart';

void main() {
  test('admin memuat ulang endpoint rentang saat bulan berubah', () async {
    final repository = _FakeAbsensiRepository();
    final bloc = AbsensiBloc(
      getSiswaList: GetAbsensiSiswaListUseCase(repository),
      getSiswaGeneral: GetAbsensiSiswaGeneralUseCase(repository),
      getGuruList: GetAbsensiGuruListUseCase(repository),
      checkIn: CheckInAbsensiUseCase(repository),
      checkOut: CheckOutAbsensiUseCase(repository),
      locationService: _FakeLocationService(),
    );

    bloc.add(const AbsensiLoadRequested(role: 'admin', bulan: 7, tahun: 2026));
    await bloc.stream.firstWhere((state) => state is AbsensiLoaded);
    bloc.add(const AbsensiMonthChanged(bulan: 6, tahun: 2026));
    await bloc.stream.firstWhere(
      (state) => state is AbsensiLoaded && state.bulan == 6,
    );

    expect(repository.ranges, [
      ('2026-07-01', '2026-07-31'),
      ('2026-06-01', '2026-06-30'),
    ]);
    await bloc.close();
  });

  test('wali tidak memanggil list umum yang tidak aman', () async {
    final repository = _FakeAbsensiRepository();
    final bloc = AbsensiBloc(
      getSiswaList: GetAbsensiSiswaListUseCase(repository),
      getSiswaGeneral: GetAbsensiSiswaGeneralUseCase(repository),
      getGuruList: GetAbsensiGuruListUseCase(repository),
      checkIn: CheckInAbsensiUseCase(repository),
      checkOut: CheckOutAbsensiUseCase(repository),
      locationService: _FakeLocationService(),
    );

    bloc.add(const AbsensiLoadRequested(role: 'wali', bulan: 7, tahun: 2026));
    final state = await bloc.stream.firstWhere(
      (state) => state is AbsensiError,
    );

    expect(
      (state as AbsensiError).message,
      contains('mencegah data siswa lain'),
    );
    expect(repository.ranges, isEmpty);
    await bloc.close();
  });

  test('siswa dapat check-in lalu riwayat dimuat ulang', () async {
    final repository = _FakeAbsensiRepository();
    final bloc = AbsensiBloc(
      getSiswaList: GetAbsensiSiswaListUseCase(repository),
      getSiswaGeneral: GetAbsensiSiswaGeneralUseCase(repository),
      getGuruList: GetAbsensiGuruListUseCase(repository),
      checkIn: CheckInAbsensiUseCase(repository),
      checkOut: CheckOutAbsensiUseCase(repository),
      locationService: _FakeLocationService(),
    );

    bloc.add(
      const AbsensiLoadRequested(
        role: 'siswa',
        profileId: 7,
        bulan: 8,
        tahun: 2026,
      ),
    );
    await bloc.stream.firstWhere((state) => state is AbsensiLoaded);
    bloc.add(const AbsensiCheckInRequested());
    await bloc.stream.firstWhere(
      (state) => state is AbsensiLoaded && state.siswaItems.isNotEmpty,
    );

    expect(repository.checkInCalls, 1);
    expect(repository.siswaListCalls, 2);
    await bloc.close();
  });

  test('error check-in backend ditampilkan tanpa reload riwayat', () async {
    final repository = _FakeAbsensiRepository()
      ..checkInFailure = const ServerFailure('Check-in ditutup oleh sekolah');
    final bloc = AbsensiBloc(
      getSiswaList: GetAbsensiSiswaListUseCase(repository),
      getSiswaGeneral: GetAbsensiSiswaGeneralUseCase(repository),
      getGuruList: GetAbsensiGuruListUseCase(repository),
      checkIn: CheckInAbsensiUseCase(repository),
      checkOut: CheckOutAbsensiUseCase(repository),
      locationService: _FakeLocationService(),
    );

    bloc.add(
      const AbsensiLoadRequested(
        role: 'siswa',
        profileId: 7,
        bulan: 8,
        tahun: 2026,
      ),
    );
    await bloc.stream.firstWhere((state) => state is AbsensiLoaded);
    bloc.add(const AbsensiCheckInRequested());
    final state = await bloc.stream.firstWhere(
      (state) => state is AbsensiError,
    );

    expect((state as AbsensiError).message, 'Check-in ditutup oleh sekolah');
    expect(repository.siswaListCalls, 1);
    await bloc.close();
  });
}

class _FakeAbsensiRepository implements AbsensiRepository {
  final List<(String?, String?)> ranges = [];
  int checkInCalls = 0;
  int siswaListCalls = 0;
  Failure? checkInFailure;

  @override
  Future<result.Result<AbsensiSiswaEntity>> checkIn(
    AttendanceLocation location,
  ) async {
    checkInCalls++;
    if (checkInFailure != null) return result.fail(checkInFailure!);
    return result.success(_attendance(checkInCalls));
  }

  @override
  Future<result.Result<AbsensiSiswaEntity>> checkOut(
    AttendanceLocation location,
  ) async => result.success(_attendance(1));

  @override
  Future<result.Result<List<AbsensiGuruEntity>>> getAbsensiGuruList(
    int guruId,
  ) async => result.success(const []);

  @override
  Future<result.Result<List<AbsensiSiswaEntity>>> getAbsensiSiswaGeneral({
    String? tanggalFrom,
    String? tanggalTo,
  }) async {
    ranges.add((tanggalFrom, tanggalTo));
    return result.success(const []);
  }

  @override
  Future<result.Result<List<AbsensiSiswaEntity>>> getAbsensiSiswaList(
    int siswaId,
  ) async {
    siswaListCalls++;
    return result.success([_attendance(siswaListCalls)]);
  }

  AbsensiSiswaEntity _attendance(int id) => AbsensiSiswaEntity(
    id: id,
    tanggal: '2026-08-13',
    statusAbsensi: 'Hadir',
    jamMasuk: '07:00:00',
    shiftNama: 'Shift Pagi',
    timezone: 'Asia/Jakarta',
  );
}

class _FakeLocationService extends AttendanceLocationService {
  @override
  Future<AttendanceLocation> capture() async => AttendanceLocation(
    latitude: -6.2,
    longitude: 106.8,
    accuracyMeter: 10,
    capturedAt: DateTime.now(),
  );
}
