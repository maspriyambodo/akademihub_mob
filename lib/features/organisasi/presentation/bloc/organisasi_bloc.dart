import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/organisasi_entity.dart';
import '../../domain/usecases/get_organisasi_list_usecase.dart';

part 'organisasi_event.dart';
part 'organisasi_state.dart';

/// Bloc daftar organisasi sekolah.
///
/// Data diambil sekali (semua status) lalu pencarian, filter status, dan
/// filter periode diterapkan di sisi client — server memang mendukung
/// `search`/`status` di jalur AG-Grid, tapi penyaringan lokal membuat
/// filter instan tanpa request ulang.
class OrganisasiBloc extends Bloc<OrganisasiEvent, OrganisasiState> {
  final GetOrganisasiListUseCase getOrganisasiList;

  bool _bolehLihat = false;

  OrganisasiBloc({required this.getOrganisasiList})
    : super(OrganisasiInitial()) {
    on<OrganisasiLoadRequested>(_onLoad);
    on<OrganisasiRefreshRequested>(_onRefresh);
    on<OrganisasiSearchChanged>(_onSearchChanged);
    on<OrganisasiStatusFilterChanged>(_onStatusFilterChanged);
    on<OrganisasiPeriodeFilterChanged>(_onPeriodeFilterChanged);
  }

  Future<void> _onLoad(
    OrganisasiLoadRequested event,
    Emitter<OrganisasiState> emit,
  ) async {
    _bolehLihat = event.bolehLihat;

    if (!_bolehLihat) {
      emit(
        const OrganisasiForbidden(
          'Akun Anda tidak memiliki izin untuk melihat data organisasi '
          '(butuh izin organisasi.view). Hubungi admin sekolah bila '
          'Anda merasa seharusnya punya akses.',
        ),
      );
      return;
    }

    emit(OrganisasiLoading());
    await _fetch(emit);
  }

  Future<void> _onRefresh(
    OrganisasiRefreshRequested event,
    Emitter<OrganisasiState> emit,
  ) async {
    if (!_bolehLihat) return;
    final sebelumnya = state;
    if (sebelumnya is! OrganisasiLoaded) {
      emit(OrganisasiLoading());
    }
    await _fetch(
      emit,
      search: sebelumnya is OrganisasiLoaded ? sebelumnya.search : '',
      filterStatus: sebelumnya is OrganisasiLoaded
          ? sebelumnya.filterStatus
          : StatusOrganisasiFilter.aktif,
      filterPeriode: sebelumnya is OrganisasiLoaded
          ? sebelumnya.filterPeriode
          : null,
    );
  }

  Future<void> _fetch(
    Emitter<OrganisasiState> emit, {
    String search = '',
    StatusOrganisasiFilter filterStatus = StatusOrganisasiFilter.aktif,
    int? filterPeriode,
  }) async {
    final hasil = await getOrganisasiList();
    if (hasil.isFailure) {
      emit(OrganisasiError(hasil.requireFailure.message));
      return;
    }

    final semua = hasil.requireData;
    // Filter periode lama bisa jadi tidak relevan setelah refresh.
    final periodeValid =
        filterPeriode != null &&
        semua.any((o) => o.periodeMulai == filterPeriode);

    emit(
      OrganisasiLoaded(
        semua: semua,
        search: search,
        filterStatus: filterStatus,
        filterPeriode: periodeValid ? filterPeriode : null,
      ),
    );
  }

  void _onSearchChanged(
    OrganisasiSearchChanged event,
    Emitter<OrganisasiState> emit,
  ) {
    final saatIni = state;
    if (saatIni is! OrganisasiLoaded) return;
    emit(saatIni.copyWith(search: event.query));
  }

  void _onStatusFilterChanged(
    OrganisasiStatusFilterChanged event,
    Emitter<OrganisasiState> emit,
  ) {
    final saatIni = state;
    if (saatIni is! OrganisasiLoaded) return;
    emit(saatIni.copyWith(filterStatus: event.filter));
  }

  void _onPeriodeFilterChanged(
    OrganisasiPeriodeFilterChanged event,
    Emitter<OrganisasiState> emit,
  ) {
    final saatIni = state;
    if (saatIni is! OrganisasiLoaded) return;
    emit(saatIni.copyWith(filterPeriode: event.periode, setPeriode: true));
  }
}
