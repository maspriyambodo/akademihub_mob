part of 'ppdb_detail_bloc.dart';

abstract class PpdbDetailState extends Equatable {
  const PpdbDetailState();

  @override
  List<Object?> get props => [];
}

class PpdbDetailInitial extends PpdbDetailState {}

class PpdbDetailLoading extends PpdbDetailState {}

class PpdbDetailError extends PpdbDetailState {
  final String message;
  const PpdbDetailError(this.message);

  @override
  List<Object?> get props => [message];
}

class PpdbDetailLoaded extends PpdbDetailState {
  final PpdbPendaftarEntity pendaftar;

  /// Dokumen pendaftar. [dokumenLengkap] = `true` bila berasal dari endpoint
  /// `/ppdb/dokumen/pendaftaran/{id}` (memuat catatan admin, ukuran, dsb.);
  /// `false` bila hanya daftar ringkas yang menempel di detail pendaftar.
  final List<PpdbDokumenEntity> dokumenList;
  final bool dokumenLengkap;

  final List<PpdbNilaiRaporEntity> nilaiList;
  final PpdbNilaiStatistikEntity nilaiStatistik;

  /// `false` bila endpoint nilai rapor gagal diakses (bagian disembunyikan).
  final bool nilaiTersedia;

  /// Hasil seleksi otomatis milik pendaftar ini, bila sudah ada.
  final PpdbHasilSeleksiEntity? hasilSeleksi;

  /// `true` selama ada aksi tulis yang sedang diproses.
  final bool sedangProses;

  /// Pesan sekali-tayang untuk SnackBar (sukses/gagal aksi).
  final String? notifikasi;
  final bool notifikasiSukses;

  /// Penanda unik tiap emit (entity dibandingkan hanya lewat `id`).
  final int versi;

  const PpdbDetailLoaded({
    required this.pendaftar,
    this.dokumenList = const [],
    this.dokumenLengkap = false,
    this.nilaiList = const [],
    this.nilaiStatistik = PpdbNilaiStatistikEntity.kosong,
    this.nilaiTersedia = false,
    this.hasilSeleksi,
    this.sedangProses = false,
    this.notifikasi,
    this.notifikasiSukses = true,
    this.versi = 0,
  });

  PpdbDetailLoaded salin({
    bool? sedangProses,
    String? notifikasi,
    bool notifikasiSukses = true,
    required int versi,
  }) {
    return PpdbDetailLoaded(
      pendaftar: pendaftar,
      dokumenList: dokumenList,
      dokumenLengkap: dokumenLengkap,
      nilaiList: nilaiList,
      nilaiStatistik: nilaiStatistik,
      nilaiTersedia: nilaiTersedia,
      hasilSeleksi: hasilSeleksi,
      sedangProses: sedangProses ?? this.sedangProses,
      notifikasi: notifikasi,
      notifikasiSukses: notifikasiSukses,
      versi: versi,
    );
  }

  @override
  List<Object?> get props => [
    pendaftar,
    dokumenList,
    dokumenLengkap,
    nilaiList,
    nilaiStatistik,
    nilaiTersedia,
    hasilSeleksi,
    sedangProses,
    notifikasi,
    notifikasiSukses,
    versi,
  ];
}
