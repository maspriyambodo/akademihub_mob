import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/tugas_siswa_entity.dart';
import '../../domain/usecases/get_pengumpulan_usecase.dart';
import '../../domain/usecases/nilai_tugas_usecase.dart';

part 'pengumpulan_event.dart';
part 'pengumpulan_state.dart';

/// BLoC untuk daftar pengumpulan pada SATU tugas (view guru) + aksi menilai.
class PengumpulanBloc extends Bloc<PengumpulanEvent, PengumpulanState> {
  final GetPengumpulanByTugasUseCase getPengumpulanByTugas;
  final NilaiTugasUseCase nilaiTugas;

  int? _tugasId;
  List<TugasSiswaEntity> _items = const [];

  PengumpulanBloc({
    required this.getPengumpulanByTugas,
    required this.nilaiTugas,
  }) : super(PengumpulanInitial()) {
    on<PengumpulanLoadRequested>(_onLoad);
    on<PengumpulanRefreshRequested>(_onRefresh);
    on<PengumpulanNilaiRequested>(_onNilai);
  }

  Future<void> _onLoad(
    PengumpulanLoadRequested event,
    Emitter<PengumpulanState> emit,
  ) async {
    _tugasId = event.tugasId;
    emit(PengumpulanLoading());
    await _fetchAndEmit(emit);
  }

  Future<void> _onRefresh(
    PengumpulanRefreshRequested event,
    Emitter<PengumpulanState> emit,
  ) async {
    emit(PengumpulanLoading());
    await _fetchAndEmit(emit);
  }

  Future<void> _onNilai(
    PengumpulanNilaiRequested event,
    Emitter<PengumpulanState> emit,
  ) async {
    final result = await nilaiTugas(
      pengumpulanId: event.pengumpulanId,
      nilai: event.nilai,
      catatanGuru: event.catatanGuru,
    );

    if (result.isSuccess) {
      final updated = result.requireData;
      _items = _items
          .map((e) => e.id == updated.id ? _mergeRelasi(e, updated) : e)
          .toList();
      emit(const PengumpulanActionSuccess('Nilai berhasil disimpan'));
    } else {
      emit(PengumpulanActionFailure(result.requireFailure.message));
    }
    emit(_buildLoaded());
  }

  Future<void> _fetchAndEmit(Emitter<PengumpulanState> emit) async {
    final tugasId = _tugasId;
    if (tugasId == null) {
      emit(const PengumpulanError('ID tugas tidak tersedia'));
      return;
    }

    final result = await getPengumpulanByTugas(tugasId);
    if (result.isFailure) {
      emit(PengumpulanError(result.requireFailure.message));
      return;
    }

    _items = result.requireData;
    emit(_buildLoaded());
  }

  /// Response endpoint `nilai` tidak memuat relasi siswa, jadi data siswa
  /// dari list lama dipertahankan.
  TugasSiswaEntity _mergeRelasi(TugasSiswaEntity lama, TugasSiswaEntity baru) =>
      TugasSiswaEntity(
        id: baru.id,
        tugasId: baru.tugasId ?? lama.tugasId,
        siswaId: baru.siswaId ?? lama.siswaId,
        jawaban: baru.jawaban ?? lama.jawaban,
        fileJawaban: baru.fileJawaban ?? lama.fileJawaban,
        waktuKumpul: baru.waktuKumpul ?? lama.waktuKumpul,
        nilai: baru.nilai ?? lama.nilai,
        catatanGuru: baru.catatanGuru ?? lama.catatanGuru,
        status: baru.status,
        statusLabel: baru.statusLabel ?? lama.statusLabel,
        siswaNama: baru.siswaNama ?? lama.siswaNama,
        siswaNis: baru.siswaNis ?? lama.siswaNis,
        tugasJudul: baru.tugasJudul ?? lama.tugasJudul,
        tugasDeskripsi: baru.tugasDeskripsi ?? lama.tugasDeskripsi,
        tugasTenggatWaktu: baru.tugasTenggatWaktu ?? lama.tugasTenggatWaktu,
        tugasKelasId: baru.tugasKelasId ?? lama.tugasKelasId,
        tugasKelasNama: baru.tugasKelasNama ?? lama.tugasKelasNama,
        tugasMapelNama: baru.tugasMapelNama ?? lama.tugasMapelNama,
        tugasGuruNama: baru.tugasGuruNama ?? lama.tugasGuruNama,
      );

  PengumpulanLoaded _buildLoaded() {
    final dinilai = _items.where((e) => e.sudahDinilai).length;
    return PengumpulanLoaded(
      items: _items,
      totalDinilai: dinilai,
      totalBelumDinilai: _items.length - dinilai,
    );
  }
}
