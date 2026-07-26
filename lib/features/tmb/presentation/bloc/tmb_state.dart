part of 'tmb_bloc.dart';

/// Satu baris daftar: tes + keikutsertaan siswa (null bila belum terdaftar
/// atau pada mode staf).
class TmbTesItem extends Equatable {
  final TmbTesEntity tes;
  final TmbPesertaEntity? peserta;

  const TmbTesItem({required this.tes, this.peserta});

  bool get belumTerdaftar => peserta == null;

  String get labelStatusKeikutsertaan =>
      peserta?.labelStatus ?? 'Belum Terdaftar';

  @override
  List<Object?> get props => [tes, peserta];
}

abstract class TmbState extends Equatable {
  const TmbState();

  @override
  List<Object?> get props => [];
}

class TmbInitial extends TmbState {}

class TmbLoading extends TmbState {}

class TmbNoAccess extends TmbState {
  final String message;
  const TmbNoAccess(this.message);

  @override
  List<Object?> get props => [message];
}

class TmbError extends TmbState {
  final String message;
  const TmbError(this.message);

  @override
  List<Object?> get props => [message];
}

class TmbLoaded extends TmbState {
  final List<TmbTesItem> items;
  final bool isModeSiswa;
  final String role;
  final int? siswaId;
  final bool canDaftar;
  final bool canMulai;
  final bool canSelesaikan;
  final bool canKirimJawaban;
  final bool canViewPeserta;
  final bool canViewPertanyaanEndpoint;
  final bool canViewHasilEndpoint;

  /// Info non-fatal (mis. daftar tes kelas gagal dimuat).
  final String? catatan;

  const TmbLoaded({
    required this.items,
    required this.isModeSiswa,
    required this.role,
    this.siswaId,
    this.canDaftar = false,
    this.canMulai = false,
    this.canSelesaikan = false,
    this.canKirimJawaban = false,
    this.canViewPeserta = false,
    this.canViewPertanyaanEndpoint = false,
    this.canViewHasilEndpoint = false,
    this.catatan,
  });

  @override
  List<Object?> get props => [
    items,
    isModeSiswa,
    role,
    siswaId,
    canDaftar,
    canMulai,
    canSelesaikan,
    canKirimJawaban,
    canViewPeserta,
    catatan,
  ];
}

/// State transien untuk snackbar; setelahnya bloc langsung meng-emit ulang
/// [TmbLoaded].
class TmbActionSuccess extends TmbState {
  final String message;
  const TmbActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class TmbActionFailure extends TmbState {
  final String message;
  const TmbActionFailure(this.message);

  @override
  List<Object?> get props => [message];
}
