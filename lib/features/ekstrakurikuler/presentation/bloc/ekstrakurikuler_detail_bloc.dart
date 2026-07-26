import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/ekstrakurikuler_entity.dart';
import '../../domain/entities/ekstrakurikuler_statistik_entity.dart';
import '../../domain/entities/pendaftaran_ekskul_entity.dart';
import '../../domain/usecases/get_ekstrakurikuler_usecase.dart';
import '../../domain/usecases/get_pendaftaran_usecase.dart';

part 'ekstrakurikuler_detail_event.dart';
part 'ekstrakurikuler_detail_state.dart';

class EkstrakurikulerDetailBloc
    extends Bloc<EkstrakurikulerDetailEvent, EkstrakurikulerDetailState> {
  final GetEkstrakurikulerDetailUseCase getEkstrakurikulerDetail;
  final GetEkstrakurikulerStatistikUseCase getEkstrakurikulerStatistik;
  final GetPesertaEkstrakurikulerUseCase getPesertaEkstrakurikuler;
  final CheckStatusPendaftaranUseCase checkStatusPendaftaran;

  int _ekstrakurikulerId = 0;
  int? _siswaId;
  bool _canViewPendaftaran = false;
  bool _terdaftarAwal = false;

  EkstrakurikulerDetailBloc({
    required this.getEkstrakurikulerDetail,
    required this.getEkstrakurikulerStatistik,
    required this.getPesertaEkstrakurikuler,
    required this.checkStatusPendaftaran,
  }) : super(EkstrakurikulerDetailInitial()) {
    on<EkstrakurikulerDetailLoadRequested>(_onLoad);
    on<EkstrakurikulerDetailRefreshRequested>(_onRefresh);
  }

  Future<void> _onLoad(
    EkstrakurikulerDetailLoadRequested event,
    Emitter<EkstrakurikulerDetailState> emit,
  ) async {
    _ekstrakurikulerId = event.ekstrakurikulerId;
    _siswaId = event.siswaId;
    _canViewPendaftaran = event.canViewPendaftaran;
    _terdaftarAwal = event.sudahTerdaftarDariDaftar;
    emit(EkstrakurikulerDetailLoading());
    await _fetch(emit);
  }

  Future<void> _onRefresh(
    EkstrakurikulerDetailRefreshRequested event,
    Emitter<EkstrakurikulerDetailState> emit,
  ) async {
    if (state is! EkstrakurikulerDetailLoaded) {
      emit(EkstrakurikulerDetailLoading());
    }
    await _fetch(emit);
  }

  Future<void> _fetch(Emitter<EkstrakurikulerDetailState> emit) async {
    final hasilDetail = await getEkstrakurikulerDetail(_ekstrakurikulerId);
    if (hasilDetail.isFailure) {
      emit(EkstrakurikulerDetailError(hasilDetail.requireFailure.message));
      return;
    }

    final hasilStatistik = await getEkstrakurikulerStatistik(
      _ekstrakurikulerId,
    );
    final statistik = hasilStatistik.isSuccess
        ? hasilStatistik.requireData
        : null;

    // Daftar peserta hanya diambil bila user punya izin melihat pendaftaran.
    var peserta = const <PendaftaranEkskulEntity>[];
    String? pesanPeserta;
    if (_canViewPendaftaran) {
      final hasilPeserta = await getPesertaEkstrakurikuler(_ekstrakurikulerId);
      if (hasilPeserta.isSuccess) {
        peserta = hasilPeserta.requireData;
      } else {
        pesanPeserta = hasilPeserta.requireFailure.message;
      }
    }

    // `check-status` mengembalikan `{terdaftar: bool}` — kontraknya cocok
    // untuk menyembunyikan tombol Daftar. Butuh izin pendaftaran.view.
    var terdaftar = _terdaftarAwal;
    final siswaId = _siswaId;
    if (siswaId != null && _canViewPendaftaran) {
      final hasilStatus = await checkStatusPendaftaran(
        siswaId: siswaId,
        ekstrakurikulerId: _ekstrakurikulerId,
      );
      if (hasilStatus.isSuccess) terdaftar = hasilStatus.requireData;
    }

    emit(
      EkstrakurikulerDetailLoaded(
        ekstrakurikuler: hasilDetail.requireData,
        statistik: statistik,
        peserta: peserta,
        pesanPeserta: pesanPeserta,
        sudahTerdaftar: terdaftar,
        dapatMelihatPeserta: _canViewPendaftaran,
      ),
    );
  }
}
