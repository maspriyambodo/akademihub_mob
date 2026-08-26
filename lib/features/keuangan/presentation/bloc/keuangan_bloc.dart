import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/laporan_periode_entity.dart';
import '../../domain/entities/pembayaran_spp_entity.dart';
import '../../domain/entities/status_pembayaran_entity.dart';
import '../../domain/entities/tarif_spp_entity.dart';
import '../../domain/entities/tunggakan_entity.dart';
import '../../domain/usecases/bayar_spp_usecase.dart';
import '../../domain/usecases/get_laporan_periode_usecase.dart';
import '../../domain/usecases/get_pembayaran_spp_usecase.dart';
import '../../domain/usecases/get_status_pembayaran_usecase.dart';
import '../../domain/usecases/get_tarif_spp_usecase.dart';
import 'keuangan_aksi_status.dart';

part 'keuangan_event.dart';
part 'keuangan_state.dart';

/// Bloc halaman utama Keuangan / SPP.
///
/// Dua mode tampilan:
/// - **Mode pribadi** (`siswa` & `wali`): ringkasan tunggakan + status bulan
///   berjalan + riwayat per bulan.
///   - `siswa` → `GET /keuangan/pembayaran-spp/siswa/{profileId}`
///   - `wali`  → profil wali TIDAK membawa id siswa, jadi memakai endpoint
///     index yang sudah difilter backend per sesi
///     (`PembayaranSppService::applySessionVisibilityFilter`), lalu id siswa
///     disimpulkan dari relasi `siswa` pada baris pertama.
/// - **Mode daftar** (`admin`, `guru`, lainnya): daftar pembayaran + pencarian
///   nama/NIS siswa + ringkasan laporan periode.
class KeuanganBloc extends Bloc<KeuanganEvent, KeuanganState> {
  final GetPembayaranListUseCase getPembayaranList;
  final GetPembayaranBySiswaUseCase getPembayaranBySiswa;
  final GetStatusPembayaranUseCase getStatusPembayaran;
  final GetTunggakanUseCase getTunggakan;
  final GetTarifSppByKelasUseCase getTarifByKelas;
  final GetLaporanPeriodeUseCase getLaporanPeriode;
  final BayarOnlineSppUseCase bayarOnline;
  final BayarMultipleSppUseCase bayarMultiple;

  String _role = '';
  int? _profileId;
  int? _kelasId;
  int? _siswaId;
  int? _tarifSppId;
  bool _canBayar = false;
  String _search = '';
  int _tahun = DateTime.now().year;

  // Laporan periode tidak berubah saat user mengetik pencarian, jadi di-cache
  // per tahun agar tidak memicu request berat setiap ketukan.
  LaporanPeriodeEntity? _laporanCache;
  int? _laporanTahun;

  KeuanganBloc({
    required this.getPembayaranList,
    required this.getPembayaranBySiswa,
    required this.getStatusPembayaran,
    required this.getTunggakan,
    required this.getTarifByKelas,
    required this.getLaporanPeriode,
    required this.bayarOnline,
    required this.bayarMultiple,
  }) : super(KeuanganInitial()) {
    on<KeuanganLoadRequested>(_onLoad);
    on<KeuanganRefreshRequested>(_onRefresh);
    on<KeuanganSearchChanged>(_onSearchChanged);
    on<KeuanganTahunChanged>(_onTahunChanged);
    on<KeuanganBayarOnlineRequested>(_onBayarOnline);
    on<KeuanganBayarMultipleRequested>(_onBayarMultiple);
  }

  bool get _isWali => _role == 'wali';
  bool get _isSiswa => _role == 'siswa';
  bool get _modePribadi => _isWali || _isSiswa;

  Future<void> _onLoad(
    KeuanganLoadRequested event,
    Emitter<KeuanganState> emit,
  ) async {
    _role = event.role;
    _profileId = event.profileId;
    _kelasId = event.kelasId;
    _canBayar = event.canBayar;
    _siswaId = event.profileId;
    _tarifSppId = null;
    _search = '';
    _laporanCache = null;
    _laporanTahun = null;
    emit(KeuanganLoading());
    await _fetchAndEmit(emit);
  }

  Future<void> _onRefresh(
    KeuanganRefreshRequested event,
    Emitter<KeuanganState> emit,
  ) async {
    _laporanCache = null;
    _laporanTahun = null;
    emit(KeuanganLoading());
    await _fetchAndEmit(emit);
  }

  Future<void> _onSearchChanged(
    KeuanganSearchChanged event,
    Emitter<KeuanganState> emit,
  ) async {
    _search = event.query;
    emit(KeuanganLoading());
    await _fetchAndEmit(emit);
  }

  Future<void> _onTahunChanged(
    KeuanganTahunChanged event,
    Emitter<KeuanganState> emit,
  ) async {
    _tahun = event.tahun;
    emit(KeuanganLoading());
    await _fetchAndEmit(emit);
  }

  // ── Pemuatan data ─────────────────────────────────────────────────────────

  Future<void> _fetchAndEmit(Emitter<KeuanganState> emit) async {
    if (_role.isEmpty) {
      emit(const KeuanganError('Data pengguna tidak tersedia'));
      return;
    }

    if (_modePribadi) {
      await _fetchPribadi(emit);
    } else {
      await _fetchDaftar(emit);
    }
  }

  Future<void> _fetchPribadi(Emitter<KeuanganState> emit) async {
    var siswaId = _profileId;
    List<PembayaranSppEntity> pembayaran;

    if (siswaId != null) {
      final hasil = await getPembayaranBySiswa(siswaId);
      if (hasil.isFailure) {
        emit(KeuanganError(hasil.requireFailure.message));
        return;
      }
      pembayaran = hasil.requireData;
    } else {
      emit(const KeuanganError('ID siswa belum dipilih'));
      return;
    }

    _siswaId = siswaId;

    final catatanBuffer = <String>[];

    // Tarif SPP: prioritas dari kelas siswa, fallback dari record pembayaran.
    TarifSppEntity? tarif;
    int? tarifSppId;
    if (_kelasId != null) {
      final hasilTarif = await getTarifByKelas(_kelasId!);
      if (hasilTarif.isSuccess) {
        tarif = hasilTarif.requireData;
        tarifSppId = tarif.id;
      }
    }
    tarifSppId ??= _cariTarifSppId(pembayaran);
    _tarifSppId = tarifSppId;

    // Rekap tunggakan memerlukan tarif SPP.
    var tunggakan = const <TunggakanEntity>[];
    if (tarifSppId != null) {
      final hasilTunggakan = await getTunggakan(
        siswaId: siswaId,
        tarifSppId: tarifSppId,
        tahun: _tahun,
      );
      if (hasilTunggakan.isSuccess) {
        tunggakan = hasilTunggakan.requireData;
      } else {
        catatanBuffer.add(
          'Rekap tunggakan belum bisa dimuat: '
          '${hasilTunggakan.requireFailure.message}',
        );
      }
    } else {
      catatanBuffer.add(
        'Tarif SPP kelas belum diketahui, rekap tunggakan dan denda '
        'tidak dapat dihitung.',
      );
    }

    // Status pembayaran per tahun ajaran (backend hanya memakai 4 digit awal).
    StatusPembayaranEntity? status;
    final hasilStatus = await getStatusPembayaran(
      siswaId,
      tahunAjaran: '$_tahun/${_tahun + 1}',
    );
    if (hasilStatus.isSuccess) status = hasilStatus.requireData;

    emit(
      KeuanganLoaded(
        role: _role,
        modePribadi: true,
        siswaId: siswaId,
        tarifSppId: tarifSppId,
        tarif: tarif,
        tahun: _tahun,
        search: _search,
        pembayaran: _urutkan(pembayaran),
        tunggakan: _urutkanTunggakan(tunggakan),
        status: status,
        catatan: catatanBuffer.isEmpty ? null : catatanBuffer.join('\n'),
      ),
    );
  }

  Future<void> _fetchDaftar(Emitter<KeuanganState> emit) async {
    final hasil = await getPembayaranList(search: _search);
    if (hasil.isFailure) {
      emit(KeuanganError(hasil.requireFailure.message));
      return;
    }

    // Pencarian sudah dijalankan server-side (jalur AG-Grid), tetapi tetap
    // disaring ulang di klien sebagai jaring pengaman bila backend
    // mengabaikan parameter `search`.
    final items = _saring(hasil.requireData, _search);

    // Laporan periode bersifat pelengkap — kegagalan tidak menggagalkan halaman.
    if (_laporanCache == null || _laporanTahun != _tahun) {
      final hasilLaporan = await getLaporanPeriode(tahun: _tahun);
      if (hasilLaporan.isSuccess) {
        _laporanCache = hasilLaporan.requireData;
        _laporanTahun = _tahun;
      }
    }
    final laporan = _laporanCache;

    emit(
      KeuanganLoaded(
        role: _role,
        modePribadi: false,
        siswaId: null,
        tarifSppId: null,
        tahun: _tahun,
        search: _search,
        pembayaran: _urutkan(items),
        laporan: laporan,
      ),
    );
  }

  // ── Aksi tulis ────────────────────────────────────────────────────────────

  Future<void> _onBayarOnline(
    KeuanganBayarOnlineRequested event,
    Emitter<KeuanganState> emit,
  ) async {
    final current = state;
    if (current is! KeuanganLoaded) return;
    if (!_canBayar) {
      emit(
        current.copyWith(
          aksiStatus: KeuanganAksiStatus.failure,
          aksiMessage: 'Anda tidak memiliki izin melakukan pembayaran',
          clearAksiUrl: true,
        ),
      );
      return;
    }
    if (current.aksiStatus == KeuanganAksiStatus.loading) return;

    final siswaId = current.siswaId ?? _siswaId;
    final tarifSppId = current.tarifSppId ?? _tarifSppId;
    if (siswaId == null || tarifSppId == null) {
      emit(
        current.copyWith(
          aksiStatus: KeuanganAksiStatus.failure,
          aksiMessage: 'Data siswa atau tarif SPP belum lengkap',
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
      siswaId: siswaId,
      tarifSppId: tarifSppId,
      bulan: event.bulan,
      tahun: event.tahun,
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

  Future<void> _onBayarMultiple(
    KeuanganBayarMultipleRequested event,
    Emitter<KeuanganState> emit,
  ) async {
    final current = state;
    if (current is! KeuanganLoaded) return;
    if (_modePribadi) {
      emit(
        current.copyWith(
          aksiStatus: KeuanganAksiStatus.failure,
          aksiMessage: 'Gunakan pembayaran online untuk melunasi tagihan',
          clearAksiUrl: true,
        ),
      );
      return;
    }
    if (!_canBayar) {
      emit(
        current.copyWith(
          aksiStatus: KeuanganAksiStatus.failure,
          aksiMessage: 'Anda tidak memiliki izin mencatat pembayaran',
          clearAksiUrl: true,
        ),
      );
      return;
    }
    if (current.aksiStatus == KeuanganAksiStatus.loading) return;
    if (event.bulan.isEmpty) return;

    final siswaId = current.siswaId ?? _siswaId;
    final tarifSppId = current.tarifSppId ?? _tarifSppId;
    if (siswaId == null || tarifSppId == null) {
      emit(
        current.copyWith(
          aksiStatus: KeuanganAksiStatus.failure,
          aksiMessage: 'Data siswa atau tarif SPP belum lengkap',
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

    final hasil = await bayarMultiple(
      siswaId: siswaId,
      tarifSppId: tarifSppId,
      bulan: event.bulan,
      tahun: event.tahun,
    );

    if (hasil.isSuccess) {
      emit(
        current.copyWith(
          aksiStatus: KeuanganAksiStatus.success,
          aksiMessage:
              '${hasil.requireData.length} bulan SPP berhasil dicatat lunas',
        ),
      );
      // Muat ulang supaya tunggakan & riwayat ikut ter-update.
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

  // ── Util ──────────────────────────────────────────────────────────────────

  int? _cariTarifSppId(List<PembayaranSppEntity> items) {
    // Utamakan record pada tahun yang sedang dilihat.
    for (final item in items) {
      if (item.tahun == _tahun && item.tarifSppId != null) {
        return item.tarifSppId;
      }
    }
    for (final item in items) {
      if (item.tarifSppId != null) return item.tarifSppId;
    }
    return null;
  }

  /// Terbaru di atas: urut tahun lalu bulan menurun, fallback id menurun.
  List<PembayaranSppEntity> _urutkan(List<PembayaranSppEntity> items) {
    final hasil = List<PembayaranSppEntity>.from(items);
    hasil.sort((a, b) {
      final tahunCmp = (b.tahun ?? 0).compareTo(a.tahun ?? 0);
      if (tahunCmp != 0) return tahunCmp;
      final bulanCmp = (b.bulan ?? 0).compareTo(a.bulan ?? 0);
      if (bulanCmp != 0) return bulanCmp;
      return b.id.compareTo(a.id);
    });
    return hasil;
  }

  List<TunggakanEntity> _urutkanTunggakan(List<TunggakanEntity> items) {
    final hasil = List<TunggakanEntity>.from(items);
    hasil.sort((a, b) {
      final tahunCmp = a.tahun.compareTo(b.tahun);
      if (tahunCmp != 0) return tahunCmp;
      return a.bulan.compareTo(b.bulan);
    });
    return hasil;
  }

  List<PembayaranSppEntity> _saring(
    List<PembayaranSppEntity> items,
    String query,
  ) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return items;

    return items.where((p) {
      final haystack = <String?>[
        p.siswaNama,
        p.siswaNis,
        p.kelasNama,
        p.namaBulan,
        p.tahun?.toString(),
        p.keterangan,
        p.status,
      ].whereType<String>().join(' ').toLowerCase();
      return haystack.contains(q);
    }).toList();
  }
}
