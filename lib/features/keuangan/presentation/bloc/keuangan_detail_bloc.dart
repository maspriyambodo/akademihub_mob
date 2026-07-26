import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/pembayaran_spp_entity.dart';
import '../../domain/entities/tunggakan_entity.dart';
import '../../domain/usecases/bayar_spp_usecase.dart';
import '../../domain/usecases/get_pembayaran_spp_usecase.dart';
import '../../domain/usecases/get_status_pembayaran_usecase.dart';
import 'keuangan_aksi_status.dart';

part 'keuangan_detail_event.dart';
part 'keuangan_detail_state.dart';

/// Bloc halaman detail satu tagihan / pembayaran SPP.
///
/// - `GET /keuangan/pembayaran-spp/{id}` untuk rincian.
/// - `GET /keuangan/pembayaran-spp/hitung-denda` untuk tagihan yang belum
///   lunas (butuh `tarif_spp_id`, `bulan`, `tahun`).
/// - `POST /keuangan/pembayaran-spp/bayar-online` → URL checkout Midtrans.
/// - `POST /keuangan/pembayaran-spp/bayar` → pencatatan lunas oleh petugas.
class KeuanganDetailBloc
    extends Bloc<KeuanganDetailEvent, KeuanganDetailState> {
  final GetPembayaranDetailUseCase getPembayaranDetail;
  final HitungDendaUseCase hitungDenda;
  final BayarOnlineSppUseCase bayarOnline;
  final BayarSppUseCase bayarSpp;

  int? _pembayaranId;

  KeuanganDetailBloc({
    required this.getPembayaranDetail,
    required this.hitungDenda,
    required this.bayarOnline,
    required this.bayarSpp,
  }) : super(KeuanganDetailInitial()) {
    on<KeuanganDetailLoadRequested>(_onLoad);
    on<KeuanganDetailRefreshRequested>(_onRefresh);
    on<KeuanganDetailBayarOnlineRequested>(_onBayarOnline);
    on<KeuanganDetailBayarTunaiRequested>(_onBayarTunai);
  }

  Future<void> _onLoad(
    KeuanganDetailLoadRequested event,
    Emitter<KeuanganDetailState> emit,
  ) async {
    _pembayaranId = event.pembayaranId;
    emit(KeuanganDetailLoading());
    await _fetchAndEmit(emit);
  }

  Future<void> _onRefresh(
    KeuanganDetailRefreshRequested event,
    Emitter<KeuanganDetailState> emit,
  ) async {
    if (_pembayaranId == null) return;
    emit(KeuanganDetailLoading());
    await _fetchAndEmit(emit);
  }

  Future<void> _fetchAndEmit(Emitter<KeuanganDetailState> emit) async {
    final id = _pembayaranId;
    if (id == null) {
      emit(const KeuanganDetailError('ID pembayaran tidak valid'));
      return;
    }

    final hasil = await getPembayaranDetail(id);
    if (hasil.isFailure) {
      emit(KeuanganDetailError(hasil.requireFailure.message));
      return;
    }

    final pembayaran = hasil.requireData;

    // Denda hanya relevan untuk tagihan yang belum lunas.
    DendaEntity? denda;
    if (!pembayaran.isLunas &&
        pembayaran.tarifSppId != null &&
        pembayaran.bulan != null &&
        pembayaran.tahun != null) {
      final hasilDenda = await hitungDenda(
        tarifSppId: pembayaran.tarifSppId!,
        bulan: pembayaran.bulan!,
        tahun: pembayaran.tahun!,
      );
      if (hasilDenda.isSuccess) denda = hasilDenda.requireData;
    }

    emit(KeuanganDetailLoaded(pembayaran: pembayaran, denda: denda));
  }

  Future<void> _onBayarOnline(
    KeuanganDetailBayarOnlineRequested event,
    Emitter<KeuanganDetailState> emit,
  ) async {
    final current = state;
    if (current is! KeuanganDetailLoaded) return;
    if (current.aksiStatus == KeuanganAksiStatus.loading) return;

    final p = current.pembayaran;
    if (!p.bisaDibayar) {
      emit(
        current.copyWith(
          aksiStatus: KeuanganAksiStatus.failure,
          aksiMessage:
              'Data tagihan tidak lengkap (siswa / tarif SPP tidak diketahui)',
          clearAksiUrl: true,
        ),
      );
      return;
    }

    emit(
      current.copyWith(
        aksiStatus: KeuanganAksiStatus.loading,
        clearAksiUrl: true,
        clearAksiMessage: true,
      ),
    );

    final hasil = await bayarOnline(
      siswaId: p.siswaId!,
      tarifSppId: p.tarifSppId!,
      bulan: p.bulan!,
      tahun: p.tahun!,
    );

    if (hasil.isSuccess) {
      emit(
        current.copyWith(
          aksiStatus: KeuanganAksiStatus.success,
          aksiUrl: hasil.requireData.checkoutUrl,
          aksiMessage: 'Membuka halaman pembayaran...',
        ),
      );
    } else {
      emit(
        current.copyWith(
          aksiStatus: KeuanganAksiStatus.failure,
          aksiMessage: hasil.requireFailure.message,
          clearAksiUrl: true,
        ),
      );
    }
  }

  Future<void> _onBayarTunai(
    KeuanganDetailBayarTunaiRequested event,
    Emitter<KeuanganDetailState> emit,
  ) async {
    final current = state;
    if (current is! KeuanganDetailLoaded) return;
    if (current.aksiStatus == KeuanganAksiStatus.loading) return;

    final p = current.pembayaran;
    if (!p.bisaDibayar) {
      emit(
        current.copyWith(
          aksiStatus: KeuanganAksiStatus.failure,
          aksiMessage: 'Data tagihan tidak lengkap',
        ),
      );
      return;
    }

    emit(
      current.copyWith(
        aksiStatus: KeuanganAksiStatus.loading,
        clearAksiUrl: true,
        clearAksiMessage: true,
      ),
    );

    final nominal = p.nominalEfektif > 0
        ? p.nominalEfektif
        : (current.denda?.nominal ?? 0);

    final hasil = await bayarSpp(
      siswaId: p.siswaId!,
      tarifSppId: p.tarifSppId!,
      bulan: p.bulan!,
      tahun: p.tahun!,
      jumlahBayar: nominal,
      status: 1, // 1 = Lunas (sys_references.status_bayar)
      metodePembayaran: event.metodePembayaran,
      keterangan: event.keterangan,
    );

    if (hasil.isSuccess) {
      emit(
        current.copyWith(
          aksiStatus: KeuanganAksiStatus.success,
          aksiMessage: 'Pembayaran berhasil dicatat',
        ),
      );
      await _fetchAndEmit(emit);
    } else {
      emit(
        current.copyWith(
          aksiStatus: KeuanganAksiStatus.failure,
          aksiMessage: hasil.requireFailure.message,
        ),
      );
    }
  }
}
