import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/bk_jenis_entity.dart';
import '../../domain/entities/bk_siswa_ringkas_entity.dart';
import '../../domain/usecases/create_bk_kasus_usecase.dart';
import '../../domain/usecases/get_bk_jenis_usecase.dart';
import '../../domain/usecases/search_bk_siswa_usecase.dart';

part 'bk_form_event.dart';
part 'bk_form_state.dart';

/// Bloc form kasus baru: memuat master jenis, mencari siswa (bila punya
/// permission `siswa.view`), dan mengirim kasus ke `POST /bk/kasus`.
class BkFormBloc extends Bloc<BkFormEvent, BkFormState> {
  final GetBkJenisListUseCase getJenisList;
  final SearchBkSiswaUseCase searchSiswa;
  final CreateBkKasusUseCase createKasus;

  List<BkJenisEntity> _jenis = const [];
  List<BkSiswaRingkasEntity> _hasilCari = const [];
  bool _sedangCari = false;
  bool _mengirim = false;
  int _revisi = 0;

  BkFormBloc({
    required this.getJenisList,
    required this.searchSiswa,
    required this.createKasus,
  }) : super(BkFormInitial()) {
    on<BkFormStarted>(_onStarted);
    on<BkFormSiswaSearchRequested>(_onCariSiswa);
    on<BkFormSubmitted>(_onSubmit);
  }

  Future<void> _onStarted(
    BkFormStarted event,
    Emitter<BkFormState> emit,
  ) async {
    emit(BkFormLoading());
    final result = await getJenisList();
    if (result.isFailure) {
      emit(BkFormError(result.requireFailure.message));
      return;
    }
    _jenis = result.requireData;
    _revisi++;
    emit(_buildReady());
  }

  Future<void> _onCariSiswa(
    BkFormSiswaSearchRequested event,
    Emitter<BkFormState> emit,
  ) async {
    if (state is! BkFormReady) return;
    final q = event.query.trim();
    if (q.length < 2) {
      _hasilCari = const [];
      _sedangCari = false;
      _revisi++;
      emit(_buildReady());
      return;
    }

    _sedangCari = true;
    _revisi++;
    emit(_buildReady());

    final result = await searchSiswa(q);
    _sedangCari = false;
    if (result.isFailure) {
      _hasilCari = const [];
      _revisi++;
      emit(BkFormActionFailure(result.requireFailure.message));
      emit(_buildReady());
      return;
    }
    _hasilCari = result.requireData;
    _revisi++;
    emit(_buildReady());
  }

  Future<void> _onSubmit(
    BkFormSubmitted event,
    Emitter<BkFormState> emit,
  ) async {
    if (_mengirim) return;
    _mengirim = true;
    _revisi++;
    emit(_buildReady());

    final result = await createKasus(
      siswaId: event.siswaId,
      guruId: event.guruId,
      jenisId: event.jenisId,
      tanggal: event.tanggal,
      keterangan: event.keterangan,
    );

    _mengirim = false;
    _revisi++;
    if (result.isFailure) {
      emit(BkFormActionFailure(result.requireFailure.message));
      emit(_buildReady());
      return;
    }

    emit(const BkFormSubmitSuccess('Kasus BK berhasil dibuat'));
    emit(_buildReady());
  }

  BkFormReady _buildReady() => BkFormReady(
    jenisList: _jenis,
    hasilCariSiswa: _hasilCari,
    sedangCariSiswa: _sedangCari,
    mengirim: _mengirim,
    revisi: _revisi,
  );
}
