import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/rapor_entity.dart';
import '../../domain/usecases/get_rapor_list_usecase.dart';

part 'rapor_event.dart';
part 'rapor_state.dart';

/// Bloc daftar rapor.
///
/// - role `siswa` (punya profileId)  → `GET /akademik/rapor/siswa/{id}`
/// - role lain (guru/admin/wali)     → `GET /akademik/rapor`
///   Backend sudah memfilter visibilitas berdasarkan role, jadi wali otomatis
///   hanya melihat rapor anaknya (profil wali tidak membawa id siswa).
class RaporBloc extends Bloc<RaporEvent, RaporState> {
  final GetRaporListUseCase getRaporList;
  final GetRaporBySiswaUseCase getRaporBySiswa;

  List<RaporEntity> _all = const [];
  String _role = '';
  int? _profileId;
  String _search = '';

  RaporBloc({required this.getRaporList, required this.getRaporBySiswa})
    : super(RaporInitial()) {
    on<RaporLoadRequested>(_onLoad);
    on<RaporSearchChanged>(_onSearchChanged);
    on<RaporRefreshRequested>(_onRefresh);
  }

  bool get _isSiswaMode => _role == 'siswa' && _profileId != null;

  Future<void> _onLoad(
    RaporLoadRequested event,
    Emitter<RaporState> emit,
  ) async {
    _role = event.role.toLowerCase();
    _profileId = event.profileId;
    _search = '';
    emit(RaporLoading());
    await _fetchAndEmit(emit);
  }

  Future<void> _onSearchChanged(
    RaporSearchChanged event,
    Emitter<RaporState> emit,
  ) async {
    _search = event.query;

    // Mode siswa: datanya sedikit, cukup filter dari cache tanpa request ulang.
    if (_role == 'siswa') {
      emit(_buildLoaded());
      return;
    }

    emit(RaporLoading());
    await _fetchAndEmit(emit);
  }

  Future<void> _onRefresh(
    RaporRefreshRequested event,
    Emitter<RaporState> emit,
  ) async {
    _all = const [];
    emit(RaporLoading());
    await _fetchAndEmit(emit);
  }

  Future<void> _fetchAndEmit(Emitter<RaporState> emit) async {
    if (_role.isEmpty) {
      emit(const RaporError('Data pengguna tidak tersedia'));
      return;
    }

    // Bila role siswa tapi `profile.id` tidak dikirim backend, endpoint index
    // tetap aman dipakai: `RaporService::applySessionVisibilityFilter()` sudah
    // membatasi hasilnya ke rapor milik siswa yang sedang login.
    final result = _isSiswaMode
        ? await getRaporBySiswa(_profileId!)
        : await getRaporList(search: _search);

    if (result.isSuccess) {
      _all = result.requireData;
      emit(_buildLoaded());
    } else {
      emit(RaporError(result.requireFailure.message));
    }
  }

  RaporLoaded _buildLoaded() {
    var items = _all;

    // Filter lokal hanya untuk mode siswa (mode daftar sudah difilter server).
    if (_role == 'siswa' && _search.trim().isNotEmpty) {
      final q = _search.trim().toLowerCase();
      items = items.where((r) {
        final haystack = [
          r.semester,
          r.tahunAjaran,
          r.kelas,
          r.siswaNama,
        ].whereType<String>().join(' ').toLowerCase();
        return haystack.contains(q);
      }).toList();
    } else {
      items = List<RaporEntity>.from(items);
    }

    // Rapor terbaru di atas.
    items.sort((a, b) => b.id.compareTo(a.id));

    return RaporLoaded(
      items: items,
      role: _role,
      search: _search,
      isSiswaMode: _role == 'siswa',
    );
  }
}
