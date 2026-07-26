part of 'ekstrakurikuler_detail_bloc.dart';

abstract class EkstrakurikulerDetailState extends Equatable {
  const EkstrakurikulerDetailState();
  @override
  List<Object?> get props => [];
}

class EkstrakurikulerDetailInitial extends EkstrakurikulerDetailState {}

class EkstrakurikulerDetailLoading extends EkstrakurikulerDetailState {}

class EkstrakurikulerDetailLoaded extends EkstrakurikulerDetailState {
  final EkstrakurikulerEntity ekstrakurikuler;

  /// Null bila endpoint statistik gagal / ekskul tidak ditemukan.
  final EkstrakurikulerStatistikEntity? statistik;

  /// Peserta berstatus aktif; kosong bila user tidak punya izin.
  final List<PendaftaranEkskulEntity> peserta;

  /// Pesan bila pengambilan peserta gagal (izin ada, request gagal).
  final String? pesanPeserta;

  final bool sudahTerdaftar;
  final bool dapatMelihatPeserta;

  const EkstrakurikulerDetailLoaded({
    required this.ekstrakurikuler,
    this.statistik,
    this.peserta = const [],
    this.pesanPeserta,
    this.sudahTerdaftar = false,
    this.dapatMelihatPeserta = false,
  });

  @override
  List<Object?> get props => [
    ekstrakurikuler,
    statistik,
    peserta,
    pesanPeserta,
    sudahTerdaftar,
    dapatMelihatPeserta,
  ];
}

class EkstrakurikulerDetailError extends EkstrakurikulerDetailState {
  final String message;
  const EkstrakurikulerDetailError(this.message);

  @override
  List<Object?> get props => [message];
}
