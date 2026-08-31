import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/absensi_siswa_entity.dart';
import '../../domain/entities/absensi_guru_entity.dart';
import '../../domain/entities/absensi_summary_entity.dart';
import '../../domain/usecases/get_absensi_siswa_usecase.dart';
import '../../domain/usecases/get_absensi_guru_usecase.dart';
import '../../data/services/attendance_location_service.dart';
import '../../../../core/error/failures.dart';

part 'absensi_event.dart';
part 'absensi_state.dart';

class AbsensiBloc extends Bloc<AbsensiEvent, AbsensiState> {
  final GetAbsensiSiswaListUseCase getSiswaList;
  final GetAbsensiSiswaGeneralUseCase getSiswaGeneral;
  final GetAbsensiGuruListUseCase getGuruList;
  final CheckInAbsensiUseCase checkIn;
  final CheckOutAbsensiUseCase checkOut;
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
    final previous = _buildLoadedForCurrentMonth();
    _actionInProgress = true;
    emit(AbsensiActionInProgress(previous));
    try {
      final location = await locationService.capture();
      final result = await checkIn(location);
      if (!result.isSuccess) {
        _emitMutationFailure(previous, result.requireFailure, emit);
        return;
      }
      _currentAttendance = result.requireData;
      await _fetchAndEmit(DateTime.now().month, DateTime.now().year, emit);
    } catch (error) {
      _emitLocationFailure(previous, error, emit);
    } finally {
      _actionInProgress = false;
    }
  }

  Future<void> _onCheckOut(
    AbsensiCheckOutRequested event,
    Emitter<AbsensiState> emit,
  ) async {
    if (_role != 'siswa' || _actionInProgress) return;
    final previous = _buildLoadedForCurrentMonth();
    _actionInProgress = true;
    emit(AbsensiActionInProgress(previous));
    try {
      final location = await locationService.capture();
      final result = await checkOut(location);
      if (!result.isSuccess) {
        _emitMutationFailure(previous, result.requireFailure, emit);
        return;
      }
      _currentAttendance = result.requireData;
      await _fetchAndEmit(DateTime.now().month, DateTime.now().year, emit);
    } catch (error) {
      _emitLocationFailure(previous, error, emit);
    } finally {
      _actionInProgress = false;
    }
  }

  void _emitMutationFailure(
    AbsensiLoaded previous,
    Failure failure,
    Emitter<AbsensiState> emit,
  ) {
    if (failure is AbsensiFailure) {
      if (failure.refreshRequired) {
        add(const AbsensiRefreshRequested());
      }
      emit(
        previous.copyWith(
          mutationMessage: failure.message,
          mutationErrorCode: failure.code,
          mutationErrorDetails: failure.details,
          clearSettingsTarget: true,
          showContactOfficer: failure.code.contains('unavailable'),
        ),
      );
      return;
    }
    emit(
      previous.copyWith(
        mutationMessage: failure.message,
        clearMutationErrorCode: true,
        clearSettingsTarget: true,
      ),
    );
  }

  void _emitLocationFailure(
    AbsensiLoaded previous,
    Object error,
    Emitter<AbsensiState> emit,
  ) {
    if (error is AttendanceLocationException) {
      emit(
        previous.copyWith(
          mutationMessage: error.message,
          mutationErrorCode: 'location_exception',
          settingsTarget: error.settingsTarget,
          clearSettingsTarget: error.settingsTarget == null,
          showContactOfficer:
              error.settingsTarget == AttendanceSettingsTarget.app,
        ),
      );
      return;
    }
    emit(
      previous.copyWith(
        mutationMessage:
            'Lokasi tidak dapat diperoleh. Coba lagi di area terbuka.',
        clearMutationErrorCode: true,
        clearSettingsTarget: true,
      ),
    );
  }

  AbsensiLoaded _buildLoadedForCurrentMonth() {
    final current = state;
    if (current is AbsensiLoaded) return current;
    if (current is AbsensiActionInProgress) return current.previous;
    return _buildLoaded(DateTime.now().month, DateTime.now().year);
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
        _reconcileCurrentAttendance();
        emit(_buildLoaded(bulan, tahun));
      } else {
        emit(AbsensiError(result.requireFailure.message));
      }
    } else if (_role == 'siswa') {
      emit(
        const AbsensiError(
          'Profil siswa belum terhubung ke akun. Hubungi administrator sekolah.',
        ),
      );
    } else if (_role == 'wali') {
      emit(
        const AbsensiError(
          'Data anak tidak tersedia pada profil wali. Akses kehadiran dihentikan '
          'untuk mencegah data siswa lain tampil.',
        ),
      );
    } else {
      // Admin memakai endpoint rentang tanggal.
      final from = '$tahun-${bulan.toString().padLeft(2, '0')}-01';
      final lastDay = DateTime(tahun, bulan + 1, 0).day;
      final to =
          '$tahun-${bulan.toString().padLeft(2, '0')}-${lastDay.toString().padLeft(2, '0')}';

      final result = await getSiswaGeneral(tanggalFrom: from, tanggalTo: to);
      if (result.isSuccess) {
        _allSiswaItems = result.requireData;
        _reconcileCurrentAttendance();
        emit(_buildLoaded(bulan, tahun));
      } else {
        emit(AbsensiError(result.requireFailure.message));
      }
    }
  }

  /// After fetching list, pick today's record as currentAttendance so that
  /// the panel shows the correct state even after app restart.
  void _reconcileCurrentAttendance() {
    if (_currentAttendance != null) {
      for (final e in _allSiswaItems) {
        if (e.id == _currentAttendance!.id ||
            e.tanggal == _currentAttendance!.tanggal) {
          _currentAttendance = e;
          return;
        }
      }
    }
    final now = DateTime.now();
    final todayStr =
        '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    for (final e in _allSiswaItems) {
      if (e.tanggal == todayStr) {
        _currentAttendance = e;
        return;
      }
    }
    _currentAttendance = null;
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
