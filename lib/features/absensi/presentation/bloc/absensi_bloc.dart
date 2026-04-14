import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/absensi_siswa_entity.dart';
import '../../domain/entities/absensi_guru_entity.dart';
import '../../domain/entities/absensi_summary_entity.dart';
import '../../domain/usecases/get_absensi_siswa_usecase.dart';
import '../../domain/usecases/get_absensi_guru_usecase.dart';

part 'absensi_event.dart';
part 'absensi_state.dart';

class AbsensiBloc extends Bloc<AbsensiEvent, AbsensiState> {
  final GetAbsensiSiswaListUseCase getSiswaList;
  final GetAbsensiSiswaGeneralUseCase getSiswaGeneral;
  final GetAbsensiGuruListUseCase getGuruList;

  // Internal cache (all records, not yet month-filtered)
  List<AbsensiSiswaEntity> _allSiswaItems = [];
  List<AbsensiGuruEntity> _allGuruItems = [];
  String _role = '';
  int? _profileId;

  AbsensiBloc({
    required this.getSiswaList,
    required this.getSiswaGeneral,
    required this.getGuruList,
  }) : super(AbsensiInitial()) {
    on<AbsensiLoadRequested>(_onLoad);
    on<AbsensiMonthChanged>(_onMonthChanged);
    on<AbsensiRefreshRequested>(_onRefresh);
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
    // Re-fetch if no cache yet, otherwise filter from cache
    if (_allSiswaItems.isEmpty && _allGuruItems.isEmpty && _role.isNotEmpty) {
      emit(AbsensiLoading());
      await _fetchAndEmit(event.bulan, event.tahun, emit);
    } else {
      emit(_buildLoaded(event.bulan, event.tahun));
    }
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
        emit(_buildLoaded(bulan, tahun));
      } else {
        emit(AbsensiError(result.requireFailure.message));
      }
    } else {
      // admin / wali / siswa without profileId → use general endpoint with month filter
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
