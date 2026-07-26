import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/organisasi_anggota_entity.dart';
import '../../domain/entities/organisasi_detail_entity.dart';
import '../../domain/usecases/get_organisasi_detail_usecase.dart';

part 'organisasi_detail_event.dart';
part 'organisasi_detail_state.dart';

/// Bloc detail organisasi: profil + struktur kepengurusan.
///
/// Seluruh anggota beserta jabatannya sudah ikut di payload
/// `GET /organisasi/{id}`, jadi pencarian nama dan filter status anggota
/// diterapkan di sisi client.
class OrganisasiDetailBloc
    extends Bloc<OrganisasiDetailEvent, OrganisasiDetailState> {
  final GetOrganisasiDetailUseCase getOrganisasiDetail;

  int _organisasiId = 0;

  OrganisasiDetailBloc({required this.getOrganisasiDetail})
    : super(OrganisasiDetailInitial()) {
    on<OrganisasiDetailLoadRequested>(_onLoad);
    on<OrganisasiDetailRefreshRequested>(_onRefresh);
    on<OrganisasiDetailSearchChanged>(_onSearchChanged);
    on<OrganisasiDetailStatusFilterChanged>(_onStatusFilterChanged);
  }

  Future<void> _onLoad(
    OrganisasiDetailLoadRequested event,
    Emitter<OrganisasiDetailState> emit,
  ) async {
    _organisasiId = event.organisasiId;
    emit(OrganisasiDetailLoading());
    await _fetch(emit);
  }

  Future<void> _onRefresh(
    OrganisasiDetailRefreshRequested event,
    Emitter<OrganisasiDetailState> emit,
  ) async {
    final sebelumnya = state;
    if (sebelumnya is! OrganisasiDetailLoaded) {
      emit(OrganisasiDetailLoading());
    }
    await _fetch(
      emit,
      search: sebelumnya is OrganisasiDetailLoaded ? sebelumnya.search : '',
      filterStatus: sebelumnya is OrganisasiDetailLoaded
          ? sebelumnya.filterStatus
          : StatusAnggotaFilter.semua,
    );
  }

  Future<void> _fetch(
    Emitter<OrganisasiDetailState> emit, {
    String search = '',
    StatusAnggotaFilter filterStatus = StatusAnggotaFilter.semua,
  }) async {
    final hasil = await getOrganisasiDetail(_organisasiId);
    if (hasil.isFailure) {
      emit(OrganisasiDetailError(hasil.requireFailure.message));
      return;
    }
    emit(
      OrganisasiDetailLoaded(
        detail: hasil.requireData,
        search: search,
        filterStatus: filterStatus,
      ),
    );
  }

  void _onSearchChanged(
    OrganisasiDetailSearchChanged event,
    Emitter<OrganisasiDetailState> emit,
  ) {
    final saatIni = state;
    if (saatIni is! OrganisasiDetailLoaded) return;
    emit(saatIni.copyWith(search: event.query));
  }

  void _onStatusFilterChanged(
    OrganisasiDetailStatusFilterChanged event,
    Emitter<OrganisasiDetailState> emit,
  ) {
    final saatIni = state;
    if (saatIni is! OrganisasiDetailLoaded) return;
    emit(saatIni.copyWith(filterStatus: event.filter));
  }
}
