import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/rapor_entity.dart';
import '../../domain/usecases/get_rapor_list_usecase.dart';
import '../../domain/usecases/manage_rapor_usecases.dart';

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
  final CreateRaporUseCase createRapor;
  final UpdateRaporUseCase updateRapor;
  final DeleteRaporUseCase deleteRapor;

  List<RaporEntity> _all = const [];
  String _role = '';
  int? _profileId;
  String _search = '';
  bool _canCreate = false;
  bool _canUpdate = false;
  bool _canDelete = false;
  bool _mutating = false;

  RaporBloc({
    required this.getRaporList,
    required this.getRaporBySiswa,
    required this.createRapor,
    required this.updateRapor,
    required this.deleteRapor,
  }) : super(RaporInitial()) {
    on<RaporLoadRequested>(_onLoad);
    on<RaporSearchChanged>(_onSearchChanged);
    on<RaporRefreshRequested>(_onRefresh);
    on<RaporCreateRequested>(_onCreate);
    on<RaporUpdateRequested>(_onUpdate);
    on<RaporDeleteRequested>(_onDelete);
  }

  bool get _isSiswaMode => _role == 'siswa' && _profileId != null;

  Future<void> _onLoad(
    RaporLoadRequested event,
    Emitter<RaporState> emit,
  ) async {
    _role = event.role.toLowerCase();
    _profileId = event.profileId;
    _canCreate = event.canCreate;
    _canUpdate = event.canUpdate;
    _canDelete = event.canDelete;
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

  Future<void> _onCreate(
    RaporCreateRequested event,
    Emitter<RaporState> emit,
  ) async {
    if (!_canCreate) {
      return _actionFailure(emit, 'Anda tidak memiliki izin membuat rapor');
    }
    if (_mutating) return;
    _mutating = true;
    final result = await createRapor(
      siswaId: event.siswaId,
      semester: event.semester,
      catatanWali: event.catatanWali,
      sakit: event.sakit,
      izin: event.izin,
      tanpaKeterangan: event.tanpaKeterangan,
    );
    _mutating = false;
    if (result.isFailure) {
      return _actionFailure(emit, result.requireFailure.message);
    }
    emit(const RaporActionSuccess('Rapor berhasil dibuat'));
    await _fetchAndEmit(emit);
  }

  Future<void> _onUpdate(
    RaporUpdateRequested event,
    Emitter<RaporState> emit,
  ) async {
    if (!_canUpdate) {
      return _actionFailure(emit, 'Anda tidak memiliki izin mengubah rapor');
    }
    if (_mutating) return;
    _mutating = true;
    final result = await updateRapor(
      id: event.id,
      catatanWali: event.catatanWali,
      sakit: event.sakit,
      izin: event.izin,
      tanpaKeterangan: event.tanpaKeterangan,
    );
    _mutating = false;
    if (result.isFailure) {
      return _actionFailure(emit, result.requireFailure.message);
    }
    emit(const RaporActionSuccess('Rapor berhasil diperbarui'));
    await _fetchAndEmit(emit);
  }

  Future<void> _onDelete(
    RaporDeleteRequested event,
    Emitter<RaporState> emit,
  ) async {
    if (!_canDelete) {
      return _actionFailure(emit, 'Anda tidak memiliki izin menghapus rapor');
    }
    if (_mutating) return;
    _mutating = true;
    final result = await deleteRapor(event.id);
    _mutating = false;
    if (result.isFailure) {
      return _actionFailure(emit, result.requireFailure.message);
    }
    emit(const RaporActionSuccess('Rapor berhasil dihapus'));
    await _fetchAndEmit(emit);
  }

  void _actionFailure(Emitter<RaporState> emit, String message) {
    emit(RaporActionFailure(message));
    emit(_buildLoaded());
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
      canCreate: _canCreate,
      canUpdate: _canUpdate,
      canDelete: _canDelete,
    );
  }
}
