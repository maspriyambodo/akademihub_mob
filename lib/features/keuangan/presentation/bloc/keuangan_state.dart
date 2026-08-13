part of 'keuangan_bloc.dart';

abstract class KeuanganState extends Equatable {
  const KeuanganState();
  @override
  List<Object?> get props => [];
}

class KeuanganInitial extends KeuanganState {}

class KeuanganLoading extends KeuanganState {}

class KeuanganLoaded extends KeuanganState {
  /// Role sudah dinormalisasi ke huruf kecil.
  final String role;

  /// true untuk siswa & wali — tampilan ringkasan tagihan pribadi.
  final bool modePribadi;

  /// Id siswa yang datanya sedang ditampilkan (null bila tidak bisa ditentukan).
  final int? siswaId;

  /// Tarif SPP yang dipakai untuk rekap tunggakan & pembayaran online.
  final int? tarifSppId;

  final TarifSppEntity? tarif;

  final int tahun;
  final String search;

  final List<PembayaranSppEntity> pembayaran;
  final List<TunggakanEntity> tunggakan;
  final StatusPembayaranEntity? status;
  final LaporanPeriodeEntity? laporan;

  /// Catatan bila ada bagian data yang tidak bisa dimuat
  /// (mis. tarif SPP kelas belum diketahui → tunggakan tidak bisa dihitung).
  final String? catatan;

  final KeuanganAksiStatus aksiStatus;

  /// URL checkout Midtrans hasil `bayar-online`.
  final String? aksiUrl;

  /// Pesan sukses/gagal aksi tulis.
  final String? aksiMessage;

  const KeuanganLoaded({
    required this.role,
    required this.modePribadi,
    required this.tahun,
    required this.search,
    this.siswaId,
    this.tarifSppId,
    this.tarif,
    this.pembayaran = const [],
    this.tunggakan = const [],
    this.status,
    this.laporan,
    this.catatan,
    this.aksiStatus = KeuanganAksiStatus.idle,
    this.aksiUrl,
    this.aksiMessage,
  });

  /// Total nominal + denda seluruh bulan menunggak.
  double get totalTunggakan =>
      tunggakan.fold<double>(0, (acc, t) => acc + t.total);

  double get totalDenda => tunggakan.fold<double>(0, (acc, t) => acc + t.denda);

  bool get adaTunggakan => tunggakan.isNotEmpty && totalTunggakan > 0;

  /// Total yang sudah dibayar (record berstatus lunas) pada [tahun].
  double get totalTerbayar => pembayaran
      .where((p) => p.isLunas && p.tahun == tahun)
      .fold<double>(0, (acc, p) => acc + p.nominalEfektif);

  /// Tagihan bulan berjalan bila datanya ada di daftar pembayaran.
  PembayaranSppEntity? get tagihanBulanIni {
    final now = DateTime.now();
    for (final p in pembayaran) {
      if (p.bulan == now.month && p.tahun == now.year) return p;
    }
    return null;
  }

  /// Tunggakan bulan berjalan (bila belum ada record pembayarannya).
  TunggakanEntity? get tunggakanBulanIni {
    final now = DateTime.now();
    for (final t in tunggakan) {
      if (t.bulan == now.month && t.tahun == now.year) return t;
    }
    return null;
  }

  /// Bulan yang boleh dilunasi lewat `bayar-multiple`.
  List<int> get bulanMenunggak =>
      tunggakan.where((t) => t.tahun == tahun).map((t) => t.bulan).toList();

  KeuanganLoaded copyWith({
    String? role,
    bool? modePribadi,
    int? siswaId,
    int? tarifSppId,
    TarifSppEntity? tarif,
    int? tahun,
    String? search,
    List<PembayaranSppEntity>? pembayaran,
    List<TunggakanEntity>? tunggakan,
    StatusPembayaranEntity? status,
    LaporanPeriodeEntity? laporan,
    String? catatan,
    KeuanganAksiStatus? aksiStatus,
    String? aksiUrl,
    String? aksiMessage,
    bool clearAksiUrl = false,
    bool clearAksiMessage = false,
  }) {
    return KeuanganLoaded(
      role: role ?? this.role,
      modePribadi: modePribadi ?? this.modePribadi,
      siswaId: siswaId ?? this.siswaId,
      tarifSppId: tarifSppId ?? this.tarifSppId,
      tarif: tarif ?? this.tarif,
      tahun: tahun ?? this.tahun,
      search: search ?? this.search,
      pembayaran: pembayaran ?? this.pembayaran,
      tunggakan: tunggakan ?? this.tunggakan,
      status: status ?? this.status,
      laporan: laporan ?? this.laporan,
      catatan: catatan ?? this.catatan,
      aksiStatus: aksiStatus ?? this.aksiStatus,
      aksiUrl: clearAksiUrl ? null : (aksiUrl ?? this.aksiUrl),
      aksiMessage: clearAksiMessage ? null : (aksiMessage ?? this.aksiMessage),
    );
  }

  @override
  List<Object?> get props => [
    role,
    modePribadi,
    siswaId,
    tarifSppId,
    tahun,
    search,
    pembayaran,
    tunggakan,
    status,
    laporan,
    catatan,
    aksiStatus,
    aksiUrl,
    aksiMessage,
  ];
}

class KeuanganError extends KeuanganState {
  final String message;
  const KeuanganError(this.message);

  @override
  List<Object?> get props => [message];
}
