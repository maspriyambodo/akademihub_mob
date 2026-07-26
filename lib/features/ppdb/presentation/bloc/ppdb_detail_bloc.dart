import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/ppdb_dokumen_entity.dart';
import '../../domain/entities/ppdb_hasil_seleksi_entity.dart';
import '../../domain/entities/ppdb_nilai_rapor_entity.dart';
import '../../domain/entities/ppdb_pendaftar_entity.dart';
import '../../domain/repositories/ppdb_repository.dart';
import '../../domain/usecases/get_ppdb_dokumen_usecase.dart';
import '../../domain/usecases/get_ppdb_hasil_seleksi_usecase.dart';
import '../../domain/usecases/get_ppdb_nilai_rapor_usecase.dart';
import '../../domain/usecases/get_ppdb_pendaftar_detail_usecase.dart';
import '../../domain/usecases/tolak_ppdb_dokumen_usecase.dart';
import '../../domain/usecases/ubah_status_ppdb_pendaftar_usecase.dart';
import '../../domain/usecases/verifikasi_ppdb_dokumen_usecase.dart';

part 'ppdb_detail_event.dart';
part 'ppdb_detail_state.dart';

class PpdbDetailBloc extends Bloc<PpdbDetailEvent, PpdbDetailState> {
  final GetPpdbPendaftarDetailUseCase getDetail;
  final GetPpdbDokumenUseCase getDokumen;
  final GetPpdbNilaiRaporUseCase getNilaiRapor;
  final GetPpdbHasilSeleksiUseCase getHasilSeleksi;
  final VerifikasiPpdbDokumenUseCase verifikasiDokumen;
  final TolakPpdbDokumenUseCase tolakDokumen;
  final UbahStatusPpdbPendaftarUseCase ubahStatusPendaftar;

  int _pendaftarId = 0;
  bool _bolehLihatDokumen = false;
  bool _bolehLihatSeleksi = false;
  int _versiState = 0;

  PpdbDetailBloc({
    required this.getDetail,
    required this.getDokumen,
    required this.getNilaiRapor,
    required this.getHasilSeleksi,
    required this.verifikasiDokumen,
    required this.tolakDokumen,
    required this.ubahStatusPendaftar,
  }) : super(PpdbDetailInitial()) {
    on<PpdbDetailLoadRequested>(_onLoad);
    on<PpdbDetailRefreshRequested>(_onRefresh);
    on<PpdbDokumenVerifikasiDiminta>(_onDokumenVerifikasi);
    on<PpdbDokumenTolakDiminta>(_onDokumenTolak);
    on<PpdbPendaftarAksiDiminta>(_onPendaftarAksi);
  }

  Future<void> _onLoad(
    PpdbDetailLoadRequested event,
    Emitter<PpdbDetailState> emit,
  ) async {
    _pendaftarId = event.pendaftarId;
    _bolehLihatDokumen = event.bolehLihatDokumen;
    _bolehLihatSeleksi = event.bolehLihatSeleksi;

    emit(PpdbDetailLoading());
    await _muatDetail(emit);
  }

  Future<void> _onRefresh(
    PpdbDetailRefreshRequested event,
    Emitter<PpdbDetailState> emit,
  ) async {
    if (_pendaftarId == 0) return;
    if (state is! PpdbDetailLoaded) emit(PpdbDetailLoading());
    await _muatDetail(emit);
  }

  Future<void> _muatDetail(
    Emitter<PpdbDetailState> emit, {
    String? notifikasi,
    bool notifikasiSukses = true,
  }) async {
    final hasilDetail = await getDetail(_pendaftarId);
    if (hasilDetail.isFailure) {
      emit(PpdbDetailError(hasilDetail.requireFailure.message));
      return;
    }
    final pendaftar = hasilDetail.requireData;

    // ── Dokumen ───────────────────────────────────────────────────────────
    // Endpoint by-pendaftaran punya permission tersendiri
    // (`ppdb.dokumen.by-pendaftaran`) yang tidak dimiliki role read-only
    // (kepala/wakil kepala sekolah). Bila tidak boleh / gagal, jatuhkan ke
    // daftar ringkas yang menempel pada detail pendaftar.
    var dokumenList = pendaftar.dokumens;
    var dokumenLengkap = false;
    if (_bolehLihatDokumen) {
      final hasilDokumen = await getDokumen(_pendaftarId);
      if (hasilDokumen.isSuccess) {
        dokumenList = hasilDokumen.requireData;
        dokumenLengkap = true;
      }
    }

    // ── Nilai rapor (pelengkap, kegagalan ditelan) ────────────────────────
    var nilaiList = const <PpdbNilaiRaporEntity>[];
    var nilaiStatistik = PpdbNilaiStatistikEntity.kosong;
    var nilaiTersedia = false;
    final hasilNilai = await getNilaiRapor(_pendaftarId);
    if (hasilNilai.isSuccess) {
      final bundle = hasilNilai.requireData;
      nilaiList = bundle.daftar;
      nilaiStatistik = bundle.statistik;
      nilaiTersedia = true;
    }

    // ── Hasil seleksi (pelengkap) ─────────────────────────────────────────
    // Tidak ada endpoint hasil-seleksi per pendaftar; ambil hasil satu
    // gelombang lalu cari baris milik pendaftar ini.
    PpdbHasilSeleksiEntity? hasilSeleksi;
    if (_bolehLihatSeleksi && pendaftar.gelombangId != null) {
      final hasil = await getHasilSeleksi(pendaftar.gelombangId!);
      if (hasil.isSuccess) {
        for (final h in hasil.requireData) {
          if (h.pendaftarId == _pendaftarId) {
            hasilSeleksi = h;
            break;
          }
        }
      }
    }

    emit(
      PpdbDetailLoaded(
        pendaftar: pendaftar,
        dokumenList: dokumenList,
        dokumenLengkap: dokumenLengkap,
        nilaiList: nilaiList,
        nilaiStatistik: nilaiStatistik,
        nilaiTersedia: nilaiTersedia,
        hasilSeleksi: hasilSeleksi,
        notifikasi: notifikasi,
        notifikasiSukses: notifikasiSukses,
        versi: ++_versiState,
      ),
    );
  }

  Future<void> _onDokumenVerifikasi(
    PpdbDokumenVerifikasiDiminta event,
    Emitter<PpdbDetailState> emit,
  ) async {
    final saatIni = state;
    if (saatIni is! PpdbDetailLoaded || saatIni.sedangProses) return;

    emit(saatIni.salin(sedangProses: true, versi: ++_versiState));
    final hasil = await verifikasiDokumen(
      event.dokumenId,
      catatan: event.catatan,
    );
    if (hasil.isFailure) {
      emit(
        saatIni.salin(
          sedangProses: false,
          notifikasi: hasil.requireFailure.message,
          notifikasiSukses: false,
          versi: ++_versiState,
        ),
      );
      return;
    }
    await _muatDetail(emit, notifikasi: 'Dokumen berhasil diverifikasi');
  }

  Future<void> _onDokumenTolak(
    PpdbDokumenTolakDiminta event,
    Emitter<PpdbDetailState> emit,
  ) async {
    final saatIni = state;
    if (saatIni is! PpdbDetailLoaded || saatIni.sedangProses) return;

    emit(saatIni.salin(sedangProses: true, versi: ++_versiState));
    final hasil = await tolakDokumen(event.dokumenId, catatan: event.catatan);
    if (hasil.isFailure) {
      emit(
        saatIni.salin(
          sedangProses: false,
          notifikasi: hasil.requireFailure.message,
          notifikasiSukses: false,
          versi: ++_versiState,
        ),
      );
      return;
    }
    await _muatDetail(emit, notifikasi: 'Dokumen ditolak dengan catatan');
  }

  Future<void> _onPendaftarAksi(
    PpdbPendaftarAksiDiminta event,
    Emitter<PpdbDetailState> emit,
  ) async {
    final saatIni = state;
    if (saatIni is! PpdbDetailLoaded || saatIni.sedangProses) return;

    emit(saatIni.salin(sedangProses: true, versi: ++_versiState));
    final hasil = await ubahStatusPendaftar(_pendaftarId, aksi: event.aksi);
    if (hasil.isFailure) {
      final failure = hasil.requireFailure;
      final pesan = failure is PpdbAccessFailure
          ? 'Anda tidak memiliki izin untuk aksi ini.'
          : failure.message;
      emit(
        saatIni.salin(
          sedangProses: false,
          notifikasi: pesan,
          notifikasiSukses: false,
          versi: ++_versiState,
        ),
      );
      return;
    }

    final label = switch (event.aksi) {
      'verify' => 'Pendaftar ditandai terverifikasi',
      'accept' => 'Pendaftar dinyatakan diterima',
      'reject' => 'Pendaftar dinyatakan ditolak',
      _ => 'Status pendaftar diperbarui',
    };
    await _muatDetail(emit, notifikasi: label);
  }
}
