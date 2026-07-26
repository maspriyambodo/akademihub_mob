import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/buku_entity.dart';
import '../../domain/entities/peminjaman_buku_entity.dart';
import '../../domain/usecases/create_peminjaman_usecase.dart';
import '../../domain/usecases/get_buku_usecase.dart';
import '../../domain/usecases/get_peminjaman_usecase.dart';
import '../../domain/usecases/proses_pengembalian_usecase.dart';

part 'perpustakaan_event.dart';
part 'perpustakaan_state.dart';

/// Bagian data yang perlu dimuat ulang.
enum PerpustakaanScope { semua, katalog, peminjaman }

class PerpustakaanBloc extends Bloc<PerpustakaanEvent, PerpustakaanState> {
  final GetBukuListUseCase getBukuList;
  final GetBukuAvailableUseCase getBukuAvailable;
  final GetPeminjamanListUseCase getPeminjamanList;
  final GetPeminjamanBySiswaUseCase getPeminjamanBySiswa;
  final GetPeminjamanOverdueUseCase getPeminjamanOverdue;
  final CreatePeminjamanUseCase createPeminjaman;
  final ProsesPengembalianUseCase prosesPengembalian;

  // ── Cache internal ─────────────────────────────────────────────────────────
  List<BukuEntity> _semuaBuku = const [];

  /// Hasil `/buku/available`, diambil malas saat filter dinyalakan.
  List<BukuEntity>? _bukuTersedia;

  List<PeminjamanBukuEntity> _peminjaman = const [];
  Set<int> _overdueIds = const <int>{};

  String? _bukuError;
  String? _peminjamanError;

  String _role = 'admin';
  int? _siswaId;
  bool _canCreate = false;
  bool _canPengembalian = false;
  bool _canLihatRiwayat = false;

  String _query = '';
  bool _hanyaTersedia = false;

  PerpustakaanBloc({
    required this.getBukuList,
    required this.getBukuAvailable,
    required this.getPeminjamanList,
    required this.getPeminjamanBySiswa,
    required this.getPeminjamanOverdue,
    required this.createPeminjaman,
    required this.prosesPengembalian,
  }) : super(PerpustakaanInitial()) {
    on<PerpustakaanLoadRequested>(_onLoad);
    on<PerpustakaanRefreshRequested>(_onRefresh);
    on<PerpustakaanSearchChanged>(_onSearchChanged);
    on<PerpustakaanHanyaTersediaChanged>(_onHanyaTersediaChanged);
    on<PerpustakaanPinjamRequested>(_onPinjam);
    on<PerpustakaanPengembalianRequested>(_onPengembalian);
  }

  // ── Handler ────────────────────────────────────────────────────────────────

  Future<void> _onLoad(
    PerpustakaanLoadRequested event,
    Emitter<PerpustakaanState> emit,
  ) async {
    _role = event.role;
    _siswaId = event.siswaId;
    _canCreate = event.canCreate;
    _canPengembalian = event.canPengembalian;
    _canLihatRiwayat = event.canLihatRiwayat;

    emit(PerpustakaanLoading());
    await _fetch(PerpustakaanScope.semua);
    emit(_buildState());
  }

  Future<void> _onRefresh(
    PerpustakaanRefreshRequested event,
    Emitter<PerpustakaanState> emit,
  ) async {
    // Tidak meng-emit Loading: RefreshIndicator sudah punya indikatornya
    // sendiri, dan tab yang tidak di-refresh tetap menampilkan datanya.
    if (state is PerpustakaanError) emit(PerpustakaanLoading());
    await _fetch(event.scope);
    emit(_buildState());
  }

  void _onSearchChanged(
    PerpustakaanSearchChanged event,
    Emitter<PerpustakaanState> emit,
  ) {
    _query = event.query;
    emit(_buildState());
  }

  Future<void> _onHanyaTersediaChanged(
    PerpustakaanHanyaTersediaChanged event,
    Emitter<PerpustakaanState> emit,
  ) async {
    _hanyaTersedia = event.value;

    // Ambil `/buku/available` sekali lalu simpan. Bila gagal, filter tetap
    // bekerja memakai perhitungan client-side (`stok > 0`).
    if (_hanyaTersedia && _bukuTersedia == null) {
      final result = await getBukuAvailable();
      if (result.isSuccess) _bukuTersedia = result.requireData;
    }

    emit(_buildState());
  }

  Future<void> _onPinjam(
    PerpustakaanPinjamRequested event,
    Emitter<PerpustakaanState> emit,
  ) async {
    if (!_canCreate) {
      emit(const PerpustakaanActionFailure('Anda tidak berhak meminjamkan buku'));
      emit(_buildState());
      return;
    }

    emit(_buildState(aksiSedangDiproses: true));

    final result = await createPeminjaman(
      siswaId: event.siswaId,
      bukuId: event.bukuId,
      tanggalPinjam: event.tanggalPinjam,
      tanggalJatuhTempo: event.tanggalJatuhTempo,
    );

    if (result.isFailure) {
      emit(PerpustakaanActionFailure(result.requireFailure.message));
      emit(_buildState());
      return;
    }

    // Stok buku ikut berubah di backend → segarkan kedua sumber data.
    _bukuTersedia = null;
    await _fetch(PerpustakaanScope.semua);
    emit(const PerpustakaanActionSuccess('Peminjaman berhasil dibuat'));
    emit(_buildState());
  }

  Future<void> _onPengembalian(
    PerpustakaanPengembalianRequested event,
    Emitter<PerpustakaanState> emit,
  ) async {
    if (!_canPengembalian) {
      emit(
        const PerpustakaanActionFailure(
          'Anda tidak berhak memproses pengembalian',
        ),
      );
      emit(_buildState());
      return;
    }

    emit(_buildState(aksiSedangDiproses: true));

    final result = await prosesPengembalian(event.peminjamanId);

    if (result.isFailure) {
      emit(PerpustakaanActionFailure(result.requireFailure.message));
      emit(_buildState());
      return;
    }

    _bukuTersedia = null;
    await _fetch(PerpustakaanScope.semua);
    emit(const PerpustakaanActionSuccess('Buku berhasil dikembalikan'));
    emit(_buildState());
  }

  // ── Pengambilan data ───────────────────────────────────────────────────────

  Future<void> _fetch(PerpustakaanScope scope) async {
    final futures = <Future<void>>[];
    if (scope != PerpustakaanScope.peminjaman) futures.add(_fetchKatalog());
    if (scope != PerpustakaanScope.katalog) futures.add(_fetchPeminjaman());
    await Future.wait(futures);
  }

  Future<void> _fetchKatalog() async {
    final result = await getBukuList();
    if (result.isSuccess) {
      _semuaBuku = result.requireData;
      _bukuError = null;
    } else {
      _bukuError = result.requireFailure.message;
    }

    // Segarkan cache "tersedia" hanya bila filternya sedang aktif.
    if (_hanyaTersedia) {
      final tersedia = await getBukuAvailable();
      if (tersedia.isSuccess) _bukuTersedia = tersedia.requireData;
    }
  }

  Future<void> _fetchPeminjaman() async {
    final siswaId = _siswaId;

    // Endpoint `/overdue` bersifat pelengkap: perhitungan keterlambatan sudah
    // dilakukan lokal dari `tanggal_jatuh_tempo`. Kegagalannya diabaikan.
    // Diambil lebih dulu supaya bisa dipakai saat mengurutkan daftar.
    final overdue = await getPeminjamanOverdue();
    _overdueIds = overdue.isSuccess
        ? overdue.requireData.map((e) => e.id).toSet()
        : const <int>{};

    // Siswa memakai endpoint miliknya sendiri. Role lain (guru/wali/admin)
    // memakai endpoint index yang sudah difilter backend per sesi — untuk wali
    // ini WAJIB karena `profile` wali tidak memuat id siswa.
    final result = (_role == 'siswa' && siswaId != null)
        ? await getPeminjamanBySiswa(siswaId)
        : await getPeminjamanList();

    if (result.isSuccess) {
      _peminjaman = _urutkan(result.requireData);
      _peminjamanError = null;
    } else {
      _peminjamanError = result.requireFailure.message;
    }
  }

  // ── Helper ─────────────────────────────────────────────────────────────────

  /// Aktif dulu (terlambat paling atas), lalu tanggal pinjam terbaru.
  List<PeminjamanBukuEntity> _urutkan(List<PeminjamanBukuEntity> items) {
    final sorted = [...items];
    sorted.sort((a, b) {
      int rank(PeminjamanBukuEntity e) {
        if (e.terlambat || (!e.sudahDikembalikan && _overdueIds.contains(e.id))) {
          return 0;
        }
        if (!e.sudahDikembalikan && !e.hilang) return 1;
        return 2;
      }

      final byRank = rank(a).compareTo(rank(b));
      if (byRank != 0) return byRank;

      final da = a.tanggalPinjamDate;
      final db = b.tanggalPinjamDate;
      if (da == null && db == null) return b.id.compareTo(a.id);
      if (da == null) return 1;
      if (db == null) return -1;
      return db.compareTo(da);
    });
    return sorted;
  }

  /// Sumber katalog: hasil `/buku/available` bila filter "hanya yang tersedia"
  /// aktif dan datanya ada, kalau tidak jatuh ke perhitungan `stok > 0`
  /// di client.
  List<BukuEntity> _sumberBuku() => _hanyaTersedia
      ? (_bukuTersedia ?? _semuaBuku.where((b) => b.tersedia).toList())
      : _semuaBuku;

  List<BukuEntity> _filterBuku(List<BukuEntity> sumber) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return sumber;

    // Pencarian judul/pengarang disaring di client. Backend sebenarnya
    // mendukung `search` pada `/perpustakaan/buku` (judul, isbn, penulis),
    // tetapi katalog sudah dimuat utuh sehingga penyaringan lokal lebih responsif.
    return sumber.where((b) => b.teksCari.contains(q)).toList();
  }

  PerpustakaanState _buildState({bool aksiSedangDiproses = false}) {
    // Gagal total di kedua sisi → layar error penuh.
    if (_bukuError != null &&
        _peminjamanError != null &&
        _semuaBuku.isEmpty &&
        _peminjaman.isEmpty) {
      return PerpustakaanError(_bukuError!);
    }

    final sumber = _sumberBuku();

    return PerpustakaanLoaded(
      buku: _filterBuku(sumber),
      totalBuku: sumber.length,
      bukuError: _semuaBuku.isEmpty ? _bukuError : null,
      peminjaman: _peminjaman,
      peminjamanError: _peminjaman.isEmpty ? _peminjamanError : null,
      overdueIds: _overdueIds,
      searchQuery: _query,
      hanyaTersedia: _hanyaTersedia,
      role: _role,
      siswaId: _siswaId,
      canCreate: _canCreate,
      canPengembalian: _canPengembalian,
      canLihatRiwayat: _canLihatRiwayat,
      aksiSedangDiproses: aksiSedangDiproses,
    );
  }
}
