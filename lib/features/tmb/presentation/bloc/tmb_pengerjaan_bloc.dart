import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/tmb_jawaban_entity.dart';
import '../../domain/entities/tmb_pertanyaan_entity.dart';
import '../../domain/entities/tmb_peserta_entity.dart';
import '../../domain/entities/tmb_tes_entity.dart';
import '../../domain/usecases/get_tmb_jawaban_by_peserta_usecase.dart';
import '../../domain/usecases/get_tmb_pertanyaan_usecase.dart';
import '../../domain/usecases/kirim_tmb_jawaban_usecase.dart';
import '../../domain/usecases/mulai_tmb_usecase.dart';
import '../../domain/usecases/selesaikan_tmb_usecase.dart';

part 'tmb_pengerjaan_event.dart';
part 'tmb_pengerjaan_state.dart';

/// Bloc alur pengerjaan tes.
///
/// - Peserta status `0` (terdaftar) → panggil `mulai` dulu.
/// - Pertanyaan diambil dari endpoint pertanyaan (staf) atau dari detail tes
///   (siswa, yang tidak punya `tes-minat-bakat-pertanyaan.view`).
/// - Jawaban tersimpan dimuat ulang dari
///   `GET /tes-minat-bakat-jawaban?peserta_id=...` sehingga pengerjaan bisa
///   dilanjutkan setelah keluar aplikasi.
/// - Setiap pilihan langsung dikirim (`POST /tes-minat-bakat-jawaban`,
///   backend melakukan upsert per pertanyaan).
class TmbPengerjaanBloc extends Bloc<TmbPengerjaanEvent, TmbPengerjaanState> {
  final MulaiTmbUseCase mulaiTes;
  final GetTmbPertanyaanUseCase getPertanyaan;
  final GetTmbJawabanByPesertaUseCase getJawabanByPeserta;
  final KirimTmbJawabanUseCase kirimJawaban;
  final SelesaikanTmbUseCase selesaikanTes;

  TmbPesertaEntity? _peserta;
  TmbTesEntity? _tes;
  bool _viaTesDetail = true;
  List<TmbPertanyaanEntity> _pertanyaan = const [];
  Map<int, TmbJawabanEntity> _jawaban = const {};
  final Set<int> _sedangMengirim = <int>{};
  bool _sedangMenyelesaikan = false;
  int _index = 0;
  String? _catatan;

  TmbPengerjaanBloc({
    required this.mulaiTes,
    required this.getPertanyaan,
    required this.getJawabanByPeserta,
    required this.kirimJawaban,
    required this.selesaikanTes,
  }) : super(TmbPengerjaanInitial()) {
    on<TmbPengerjaanStarted>(_onStarted);
    on<TmbPengerjaanIndexChanged>(_onIndexChanged);
    on<TmbPengerjaanOpsiDipilih>(_onOpsiDipilih);
    on<TmbPengerjaanTeksDikirim>(_onTeksDikirim);
    on<TmbPengerjaanSelesaikanRequested>(_onSelesaikan);
  }

  Future<void> _onStarted(
    TmbPengerjaanStarted event,
    Emitter<TmbPengerjaanState> emit,
  ) async {
    _peserta = event.peserta;
    _tes = event.tes;
    _viaTesDetail = event.viaTesDetail;
    _catatan = null;
    emit(TmbPengerjaanLoading());

    var peserta = event.peserta;

    // Peserta yang baru terdaftar harus memulai tes dulu (mencatat waktu
    // mulai dan mengubah status menjadi "sedang mengerjakan").
    if (peserta.isTerdaftar) {
      final hasilMulai = await mulaiTes(peserta.id);
      if (hasilMulai.isFailure) {
        emit(TmbPengerjaanError(hasilMulai.requireFailure.message));
        return;
      }
      final mulai = hasilMulai.requireData;
      peserta = peserta.copyWith(
        status: mulai.status,
        waktuMulai: mulai.waktuMulai,
      );
    }
    _peserta = peserta;

    final hasilPertanyaan = await getPertanyaan(
      event.tes.id,
      viaTesDetail: _viaTesDetail,
    );
    if (hasilPertanyaan.isFailure) {
      emit(TmbPengerjaanError(hasilPertanyaan.requireFailure.message));
      return;
    }
    _pertanyaan = hasilPertanyaan.requireData;

    if (_pertanyaan.isEmpty) {
      emit(
        const TmbPengerjaanError(
          'Tes ini belum memiliki pertanyaan. Hubungi admin sekolah.',
        ),
      );
      return;
    }

    // Muat jawaban tersimpan agar bisa melanjutkan dari posisi terakhir.
    _jawaban = const {};
    final hasilJawaban = await getJawabanByPeserta(peserta.id);
    if (hasilJawaban.isSuccess) {
      _jawaban = {
        for (final j in hasilJawaban.requireData)
          if (j.pesertaId == peserta.id) j.pertanyaanId: j,
      };
    } else if (!event.pesertaBaruMulai) {
      _catatan =
          'Jawaban tersimpan gagal dimuat — jawaban baru tetap tersimpan '
          'di server.';
    }

    // Lompat ke pertanyaan pertama yang belum terjawab.
    _index = 0;
    for (var i = 0; i < _pertanyaan.length; i++) {
      if (!_jawaban.containsKey(_pertanyaan[i].id)) {
        _index = i;
        break;
      }
      if (i == _pertanyaan.length - 1) _index = i;
    }

    emit(_buildLoaded());
  }

  void _onIndexChanged(
    TmbPengerjaanIndexChanged event,
    Emitter<TmbPengerjaanState> emit,
  ) {
    if (state is! TmbPengerjaanLoaded) return;
    if (event.index < 0 || event.index >= _pertanyaan.length) return;
    _index = event.index;
    emit(_buildLoaded());
  }

  Future<void> _onOpsiDipilih(
    TmbPengerjaanOpsiDipilih event,
    Emitter<TmbPengerjaanState> emit,
  ) async {
    await _kirim(
      emit,
      pertanyaanId: event.pertanyaanId,
      opsiId: event.opsiId,
    );
  }

  Future<void> _onTeksDikirim(
    TmbPengerjaanTeksDikirim event,
    Emitter<TmbPengerjaanState> emit,
  ) async {
    final teks = event.teks.trim();
    if (teks.isEmpty) return;
    await _kirim(emit, pertanyaanId: event.pertanyaanId, jawabanTeks: teks);
  }

  Future<void> _kirim(
    Emitter<TmbPengerjaanState> emit, {
    required int pertanyaanId,
    int? opsiId,
    String? jawabanTeks,
  }) async {
    final peserta = _peserta;
    if (peserta == null || state is! TmbPengerjaanLoaded) return;
    if (_sedangMengirim.contains(pertanyaanId)) return;

    _sedangMengirim.add(pertanyaanId);
    emit(_buildLoaded());

    final hasil = await kirimJawaban(
      pesertaId: peserta.id,
      pertanyaanId: pertanyaanId,
      opsiId: opsiId,
      jawabanTeks: jawabanTeks,
    );

    _sedangMengirim.remove(pertanyaanId);

    if (hasil.isFailure) {
      emit(TmbPengerjaanActionFailure(hasil.requireFailure.message));
      emit(_buildLoaded());
      return;
    }

    _jawaban = {..._jawaban, pertanyaanId: hasil.requireData};
    emit(_buildLoaded());
  }

  Future<void> _onSelesaikan(
    TmbPengerjaanSelesaikanRequested event,
    Emitter<TmbPengerjaanState> emit,
  ) async {
    final peserta = _peserta;
    if (peserta == null || state is! TmbPengerjaanLoaded) return;
    if (_sedangMenyelesaikan) return;

    _sedangMenyelesaikan = true;
    emit(_buildLoaded());

    final hasil = await selesaikanTes(peserta.id);
    _sedangMenyelesaikan = false;

    if (hasil.isFailure) {
      emit(TmbPengerjaanActionFailure(hasil.requireFailure.message));
      emit(_buildLoaded());
      return;
    }

    // Response `selesaikan` memuat peserta segar beserta `hasil.aspek`.
    emit(TmbPengerjaanSelesai(hasil.requireData));
  }

  TmbPengerjaanLoaded _buildLoaded() => TmbPengerjaanLoaded(
    peserta: _peserta!,
    tes: _tes!,
    pertanyaan: _pertanyaan,
    jawaban: Map<int, TmbJawabanEntity>.unmodifiable(_jawaban),
    index: _index,
    sedangMengirim: Set<int>.unmodifiable(_sedangMengirim),
    sedangMenyelesaikan: _sedangMenyelesaikan,
    catatan: _catatan,
  );
}
