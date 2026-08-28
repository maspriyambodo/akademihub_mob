import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/absensi_siswa_entity.dart';
import '../../domain/entities/absensi_guru_entity.dart';
import '../../domain/entities/absensi_summary_entity.dart';
import '../../domain/usecases/get_absensi_siswa_usecase.dart';
import '../../domain/usecases/get_absensi_guru_usecase.dart';
import '../../data/services/attendance_location_service.dart';

part 'absensi_event.dart';
part 'absensi_state.dart';

class AbsensiBloc extends Bloc<AbsensiEvent, AbsensiState> {
  final GetAbsensiSiswaListUseCase getSiswaList;
  final GetAbsensiSiswaGeneralUseCase getSiswaGeneral;
  final GetAbsensiGuruListUseCase getGuruList;
  final CheckInAbsensiUseCase checkIn;
  final CheckOutAbsensiUseCase checkOut;
  final GetCurrentAbsensiUseCase getCurrent;
  final AttendanceLocationService locationService;
  bool _actionInProgress = false;

  // Internal cache (all records, not yet month-filtered)
  List<AbsensiSiswaEntity> _allSiswaItems = [];
  List<AbsensiGuruEntity> _allGuruItems = [];
  String _role = '';
  int? _profileId;
  AbsensiSiswaEntity? _currentAttendance;

  AbsensiBloc({
    required this.getSiswaList,
    required this.getSiswaGeneral,
    required this.getGuruList,
    required this.checkIn,
    required this.checkOut,
    required this.getCurrent,
    required this.locationService,
  }) : super(AbsensiInitial()) {
    on<AbsensiLoadRequested>(_onLoad);
    on<AbsensiMonthChanged>(_onMonthChanged);
    on<AbsensiRefreshRequested>(_onRefresh);
    on<AbsensiCheckInRequested>(_onCheckIn);
    on<AbsensiCheckOutRequested>(_onCheckOut);
  }

  Future<void> _onCheckIn(
    AbsensiCheckInRequested event,
    Emitter<AbsensiState> emit,
  ) async {
    if (_role != 'siswa' || _actionInProgress) return;
    _actionInProgress = true;
    emit(AbsensiActionInProgress(_buildLoadedForCurrentMonth()));
    try {
      final location = await locationService.capture();
      final result = await checkIn(location);
      if (!result.isSuccess) {
        emit(AbsensiError(result.requireFailure.message));
        return;
      }
      await _fetchAndEmit(DateTime.now().month, DateTime.now().year, emit);
    } catch (error) {
      emit(AbsensiError(_locationError(error)));
    } finally {
      _actionInProgress = false;
    }
  }

  Future<void> _onCheckOut(
    AbsensiCheckOutRequested event,
    Emitter<AbsensiState> emit,
  ) async {
    if (_role != 'siswa' || _actionInProgress) return;
    _actionInProgress = true;
    emit(AbsensiActionInProgress(_buildLoadedForCurrentMonth()));
    try {
      final location = await locationService.capture();
      final result = await checkOut(location);
      if (!result.isSuccess) {
        emit(AbsensiError(result.requireFailure.message));
        return;
      }
      await _fetchAndEmit(DateTime.now().month, DateTime.now().year, emit);
    } catch (error) {
      emit(AbsensiError(_locationError(error)));
    } finally {
      _actionInProgress = false;
    }
  }

  AbsensiLoaded _buildLoadedForCurrentMonth() {
    final current = state;
    if (current is AbsensiLoaded) return current;
    return _buildLoaded(DateTime.now().month, DateTime.now().year);
  }

  String _locationError(Object error) {
    if (error is StateError) return error.message;
    return 'Lokasi tidak dapat diperoleh. Coba lagi di area terbuka.';
  }

  Future<void> _onLoad(
    AbsensiLoadRequested event,
    Emitter<AbsensiState> emit,
  ) async {
    emit(AbsensiLoading());
    _role = event.role;
    _profileId = event.profileId;
    await _fetchAndEmit(event.bulan, event.tahun, emit);
  }

  Future<void> _onMonthChanged(
    AbsensiMonthChanged event,
    Emitter<AbsensiState> emit,
  ) async {
    // Endpoint umum diminta per bulan. Cache-nya tidak mewakili bulan lain.
    if (_role != 'guru' && _role != 'siswa') {
      _allSiswaItems = [];
      emit(AbsensiLoading());
      await _fetchAndEmit(event.bulan, event.tahun, emit);
      return;
    }

    emit(_buildLoaded(event.bulan, event.tahun));
  }

  Future<void> _onRefresh(
    AbsensiRefreshRequested event,
    Emitter<AbsensiState> emit,
  ) async {
    final current = state;
    final bulan = current is AbsensiLoaded
        ? current.bulan
        : DateTime.now().month;
    final tahun = current is AbsensiLoaded
        ? current.tahun
        : DateTime.now().year;
    _allSiswaItems = [];
    _allGuruItems = [];
    emit(AbsensiLoading());
    await _fetchAndEmit(bulan, tahun, emit);
  }

  Future<void> _fetchAndEmit(
    int bulan,
    int tahun,
    Emitter<AbsensiState> emit,
  ) async {
    if (_role == 'guru') {
      if (_profileId == null) {
        emit(const AbsensiError('ID guru tidak tersedia'));
        return;
      }
      final result = await getGuruList(_profileId!);
      if (result.isSuccess) {
        _allGuruItems = result.requireData;
        emit(_buildLoaded(bulan, tahun));
      } else {
        emit(AbsensiError(result.requireFailure.message));
      }
    } else if (_role == 'siswa' && _profileId != null) {
      final result = await getSiswaList(_profileId!);
      if (result.isSuccess) {
        _allSiswaItems = result.requireData;
        final currentResult = await getCurrent();
        if (!currentResult.isSuccess) {
          emit(AbsensiError(currentResult.requireFailure.message));
          return;
        }
        _currentAttendance = currentResult.requireData;
        emit(_buildLoaded(bulan, tahun));
      } else {
        emit(AbsensiError(result.requireFailure.message));
      }
    } else if (_role == 'wali') {
      emit(
        const AbsensiError(
          'Data anak tidak tersedia pada profil wali. Akses kehadiran dihentikan '
          'untuk mencegah data siswa lain tampil.',
        ),
      );
    } else {
      // admin / siswa tanpa profileId memakai endpoint rentang tanggal.
      final from = '$tahun-${bulan.toString().padLeft(2, '0')}-01';
      final lastDay = DateTime(tahun, bulan + 1, 0).day;
      final to =
          '$tahun-${bulan.toString().padLeft(2, '0')}-${lastDay.toString().padLeft(2, '0')}';

      final result = await getSiswaGeneral(tanggalFrom: from, tanggalTo: to);
      if (result.isSuccess) {
        _allSiswaItems = result.requireData;
        emit(_buildLoaded(bulan, tahun));
      } else {
        emit(AbsensiError(result.requireFailure.message));
      }
    }
  }

  AbsensiLoaded _buildLoaded(int bulan, int tahun) {
    final siswaFiltered = _role == 'guru'
        ? <AbsensiSiswaEntity>[]
        : _filterSiswaByMonth(_allSiswaItems, bulan, tahun);
    final guruFiltered = _role == 'guru'
        ? _filterGuruByMonth(_allGuruItems, bulan, tahun)
        : <AbsensiGuruEntity>[];

    return AbsensiLoaded(
      summary: _role == 'guru'
          ? _computeGuruSummary(guruFiltered)
          : _computeSiswaSummary(siswaFiltered),
      siswaItems: siswaFiltered,
      guruItems: guruFiltered,
      bulan: bulan,
      tahun: tahun,
      role: _role,
      currentAttendance: _currentAttendance,
    );
  }

  List<AbsensiSiswaEntity> _filterSiswaByMonth(
    List<AbsensiSiswaEntity> all,
    int bulan,
    int tahun,
  ) {
    return all.where((e) {
      final d = e.tanggalDate;
      return d != null && d.month == bulan && d.year == tahun;
    }).toList()..sort((a, b) => b.tanggal.compareTo(a.tanggal)); // newest first
  }

  List<AbsensiGuruEntity> _filterGuruByMonth(
    List<AbsensiGuruEntity> all,
    int bulan,
    int tahun,
  ) {
    return all.where((e) {
      final d = e.tanggalDate;
      return d != null && d.month == bulan && d.year == tahun;
    }).toList()..sort((a, b) => b.tanggal.compareTo(a.tanggal));
  }

  AbsensiSummaryEntity _computeSiswaSummary(List<AbsensiSiswaEntity> items) {
    int hadir = 0, izin = 0, sakit = 0, alpha = 0;
    for (final e in items) {
      final s = e.statusAbsensi.toLowerCase();
      if (s.contains('hadir')) {
        hadir++;
      } else if (s.contains('izin')) {
        izin++;
      } else if (s.contains('sakit')) {
        sakit++;
      } else if (s.contains('alp')) {
        alpha++;
      }
    }
    return AbsensiSummaryEntity(
      hadir: hadir,
      izin: izin,
      sakit: sakit,
      alpha: alpha,
      total: items.length,
    );
  }

  AbsensiSummaryEntity _computeGuruSummary(List<AbsensiGuruEntity> items) {
    int hadir = 0, izin = 0, sakit = 0, alpha = 0;
    for (final e in items) {
      final s = e.statusAbsensi.toLowerCase();
      if (s.contains('hadir')) {
        hadir++;
      } else if (s.contains('izin')) {
        izin++;
      } else if (s.contains('sakit')) {
        sakit++;
      } else if (s.contains('alp')) {
        alpha++;
      }
    }
    return AbsensiSummaryEntity(
      hadir: hadir,
      izin: izin,
      sakit: sakit,
      alpha: alpha,
      total: items.length,
    );
  }
}
