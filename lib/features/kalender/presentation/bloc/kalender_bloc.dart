import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/kalender_agenda_item.dart';
import '../../domain/entities/kalender_event_entity.dart';
import '../../domain/entities/kalender_harian_entity.dart';
import '../../domain/entities/kalender_konteks_entity.dart';
import '../../domain/entities/kalender_tipe_entity.dart';
import '../../domain/repositories/kalender_repository.dart';
import '../../domain/usecases/get_kalender_events_usecase.dart';
import '../../domain/usecases/get_kalender_harian_usecase.dart';
import '../../domain/usecases/get_kalender_konteks_usecase.dart';
import '../../domain/usecases/get_kalender_tipe_usecase.dart';

part 'kalender_event.dart';
part 'kalender_state.dart';

class KalenderBloc extends Bloc<KalenderEvent, KalenderState> {
  final GetKalenderEventsUseCase getEvents;
  final GetKalenderHarianUseCase getHarian;
  final GetKalenderTipeUseCase getTipe;
  final GetKalenderKonteksUseCase getKonteks;

  // ── Cache sisi klien (semua data, belum difilter bulan) ───────────────────
  List<KalenderEventEntity> _events = const [];
  List<KalenderHarianEntity> _harian = const [];
  List<KalenderTipeEntity> _tipeList = const [];
  KalenderKonteksEntity _konteks = KalenderKonteksEntity.kosong;
  bool _harianTersedia = true;

  bool _bolehLihatKalender = false;
  bool _bolehLihatHarian = true;
  bool _bolehLihatTipe = true;
  String _role = '';
  int? _filterTipeId;
  int _bulan = DateTime.now().month;
  int _tahun = DateTime.now().year;

  KalenderBloc({
    required this.getEvents,
    required this.getHarian,
    required this.getTipe,
    required this.getKonteks,
  }) : super(KalenderInitial()) {
    on<KalenderLoadRequested>(_onLoad);
    on<KalenderMonthChanged>(_onMonthChanged);
    on<KalenderTipeFilterChanged>(_onTipeFilterChanged);
    on<KalenderRefreshRequested>(_onRefresh);
  }

  Future<void> _onLoad(
    KalenderLoadRequested event,
    Emitter<KalenderState> emit,
  ) async {
    _role = event.role;
    _bolehLihatKalender = event.bolehLihatKalender;
    _bolehLihatHarian = event.bolehLihatHarian;
    _bolehLihatTipe = event.bolehLihatTipe;
    _bulan = event.bulan;
    _tahun = event.tahun;

    if (!_bolehLihatKalender) {
      emit(KalenderForbidden(_pesanTanpaIzin()));
      return;
    }

    emit(KalenderLoading());
    await _ambilData(emit);
  }

  Future<void> _onRefresh(
    KalenderRefreshRequested event,
    Emitter<KalenderState> emit,
  ) async {
    if (!_bolehLihatKalender) {
      emit(KalenderForbidden(_pesanTanpaIzin()));
      return;
    }
    _events = const [];
    _harian = const [];
    emit(KalenderLoading());
    await _ambilData(emit);
  }

  void _onMonthChanged(
    KalenderMonthChanged event,
    Emitter<KalenderState> emit,
  ) {
    _bulan = event.bulan;
    _tahun = event.tahun;
    if (state is KalenderLoaded) emit(_bangunLoaded());
  }

  void _onTipeFilterChanged(
    KalenderTipeFilterChanged event,
    Emitter<KalenderState> emit,
  ) {
    _filterTipeId = event.tipeId;
    if (state is KalenderLoaded) emit(_bangunLoaded());
  }

  // ── Pengambilan data ──────────────────────────────────────────────────────

  Future<void> _ambilData(Emitter<KalenderState> emit) async {
    final hasilEvent = await getEvents();
    if (hasilEvent.isFailure) {
      final failure = hasilEvent.requireFailure;
      if (failure is KalenderAccessFailure) {
        emit(KalenderForbidden(_pesanTanpaIzin(failure.message)));
      } else {
        emit(KalenderError(failure.message));
      }
      return;
    }
    _events = hasilEvent.requireData;

    // Tipe & agenda harian bersifat pelengkap: kegagalannya tidak boleh
    // menggagalkan halaman.
    if (_bolehLihatTipe) {
      final hasilTipe = await getTipe();
      _tipeList = hasilTipe.isSuccess ? hasilTipe.requireData : const [];
    } else {
      _tipeList = const [];
    }
    if (_tipeList.isEmpty) _tipeList = _tipeDariEvent();

    if (_bolehLihatHarian) {
      final hasilHarian = await getHarian();
      _harianTersedia = hasilHarian.isSuccess;
      _harian = hasilHarian.isSuccess ? hasilHarian.requireData : const [];
    } else {
      _harianTersedia = false;
      _harian = const [];
    }

    final hasilKonteks = await getKonteks();
    _konteks = hasilKonteks.isSuccess
        ? hasilKonteks.requireData
        : KalenderKonteksEntity.kosong;

    emit(_bangunLoaded());
  }

  /// Fallback daftar tipe bila endpoint `kalender-tipe` tidak dapat diakses:
  /// ambil dari objek `tipe` yang sudah menempel di tiap event.
  List<KalenderTipeEntity> _tipeDariEvent() {
    final map = <int, KalenderTipeEntity>{};
    for (final e in _events) {
      final t = e.tipe;
      if (t != null) map[t.id] = t;
    }
    final list = map.values.toList()
      ..sort((a, b) => a.nama.toLowerCase().compareTo(b.nama.toLowerCase()));
    return list;
  }

  // ── Penyusunan linimasa ───────────────────────────────────────────────────

  /// Menggabungkan event akademik dan agenda harian menjadi SATU linimasa.
  ///
  /// Aturan: setiap baris `kalender-harian` menempel pada satu event akademik
  /// (FK `kalender_id`, unique bersama `tanggal`) dan biasanya hanya penjabaran
  /// per hari dari event tersebut. Maka baris harian ditampilkan hanya bila:
  ///   1. event induknya TIDAK ada di data yang dimuat (agenda "yatim"), atau
  ///   2. baris itu membawa informasi tambahan — statusnya bukan aktif
  ///      (dibatalkan/selesai) atau punya `catatan`.
  /// Baris harian yang sekadar mengulang event induknya dibuang supaya
  /// linimasa tidak berisi duplikat.
  List<KalenderAgendaItem> _semuaAgenda() {
    final eventById = <int, KalenderEventEntity>{
      for (final e in _events) e.id: e,
    };
    final tipeById = <int, KalenderTipeEntity>{
      for (final t in _tipeList) t.id: t,
    };

    final items = <KalenderAgendaItem>[
      for (final e in _events) KalenderAgendaItem.dariEvent(e),
    ];

    for (final h in _harian) {
      if (h.tanggal.isEmpty) continue;
      final induk = h.kalenderId == null ? null : eventById[h.kalenderId];
      if (induk != null && !h.punyaInfoTambahan) continue;
      items.add(
        KalenderAgendaItem.dariHarian(
          h,
          tipe: h.eventTipeId == null ? null : tipeById[h.eventTipeId],
          induk: induk,
        ),
      );
    }

    if (_filterTipeId != null) {
      return items.where((i) => i.tipe?.id == _filterTipeId).toList();
    }
    return items;
  }

  KalenderLoaded _bangunLoaded() {
    final semua = _semuaAgenda();
    final sekarang = DateTime.now();
    final hariIni = DateTime(sekarang.year, sekarang.month, sekarang.day);
    final bulanIniDipilih = _bulan == sekarang.month && _tahun == sekarang.year;

    final agendaHariIni =
        semua.where((i) => i.sedangBerlangsung(hariIni)).toList()
          ..sort(_bandingkan);

    final idHariIni = agendaHariIni.map((i) => i.id).toSet();

    // Agenda bulan terpilih: rentangnya bersinggungan dengan bulan tersebut.
    final awalBulan = DateTime(_tahun, _bulan, 1);
    final akhirBulan = DateTime(_tahun, _bulan + 1, 0);

    final bulanIni = <KalenderAgendaItem>[];
    for (final i in semua) {
      final mulai = i.mulaiDate;
      if (mulai == null) continue;
      final akhir = i.akhirEfektifDate ?? mulai;
      final mulaiHari = DateTime(mulai.year, mulai.month, mulai.day);
      final akhirHari = DateTime(akhir.year, akhir.month, akhir.day);
      if (akhirHari.isBefore(awalBulan) || mulaiHari.isAfter(akhirBulan)) {
        continue;
      }
      bulanIni.add(i);
    }

    final totalBulanIni = bulanIni.length;

    // Agenda hari ini sudah tampil di bagian atas; jangan diulang di daftar.
    final untukDikelompokkan = bulanIniDipilih
        ? bulanIni.where((i) => !idHariIni.contains(i.id)).toList()
        : bulanIni;

    return KalenderLoaded(
      konteks: _konteks,
      tipeList: _tipeList,
      agendaHariIni: bulanIniDipilih ? agendaHariIni : const [],
      grupBulanIni: _kelompokkanPerTanggal(
        untukDikelompokkan,
        awalBulan,
        akhirBulan,
      ),
      bulan: _bulan,
      tahun: _tahun,
      totalBulanIni: totalBulanIni,
      filterTipeId: _filterTipeId,
      harianTersedia: _harianTersedia,
    );
  }

  /// Mengelompokkan per tanggal. Untuk agenda multi-hari yang dimulai sebelum
  /// bulan terpilih, jangkarnya digeser ke tanggal 1 bulan itu supaya tetap
  /// muncul di urutan yang benar.
  List<KalenderGrupTanggal> _kelompokkanPerTanggal(
    List<KalenderAgendaItem> items,
    DateTime awalBulan,
    DateTime akhirBulan,
  ) {
    final peta = <String, List<KalenderAgendaItem>>{};
    for (final i in items) {
      final mulai = i.mulaiDate;
      if (mulai == null) continue;
      final jangkar = mulai.isBefore(awalBulan) ? awalBulan : mulai;
      final kunci = _kunciTanggal(jangkar);
      peta.putIfAbsent(kunci, () => <KalenderAgendaItem>[]).add(i);
    }

    final kunciUrut = peta.keys.toList()..sort();
    return [
      for (final k in kunciUrut)
        KalenderGrupTanggal(tanggal: k, items: peta[k]!..sort(_bandingkan)),
    ];
  }

  static String _kunciTanggal(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// Urutan dalam satu tanggal: prioritas tinggi dulu, lalu jam mulai,
  /// lalu judul.
  static int _bandingkan(KalenderAgendaItem a, KalenderAgendaItem b) {
    final p = a.prioritas.compareTo(b.prioritas);
    if (p != 0) return p;
    final wa = a.waktuMulai ?? '99:99';
    final wb = b.waktuMulai ?? '99:99';
    final w = wa.compareTo(wb);
    if (w != 0) return w;
    return a.judul.toLowerCase().compareTo(b.judul.toLowerCase());
  }

  String _pesanTanpaIzin([String? dariServer]) {
    if (dariServer != null && dariServer.trim().isNotEmpty) {
      final lower = dariServer.toLowerCase();
      // Pesan bawaan middleware berbahasa Inggris; ganti dengan pesan lokal.
      if (!lower.contains('permission') &&
          !lower.contains('forbidden') &&
          !lower.contains('unauthorized')) {
        return dariServer;
      }
    }
    final peran = _role.trim().isEmpty ? 'akun Anda' : 'peran $_role';
    return 'Kalender akademik hanya dapat diakses oleh pengelola sekolah '
        '(izin "kalender-akademik.view"). Saat ini $peran belum memilikinya. '
        'Hubungi admin sekolah bila Anda memerlukan akses.';
  }
}
