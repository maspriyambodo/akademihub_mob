part of 'profil_bloc.dart';

abstract class ProfilState extends Equatable {
  const ProfilState();

  @override
  List<Object?> get props => [];
}

class ProfilInitial extends ProfilState {}

class ProfilLoading extends ProfilState {}

class ProfilLoaded extends ProfilState {
  final SekolahEntity? sekolah;

  /// true bila [sekolah] berasal dari tenant tersimpan (bukan endpoint API),
  /// sehingga NPSN/alamat tidak tersedia.
  final bool sekolahDariCache;
  final String? sekolahError;

  final List<PerangkatEntity> perangkat;

  /// User punya permission `users.view` → kartu perangkat ditampilkan.
  final bool perangkatTersedia;
  final String? perangkatError;

  final AppInfoEntity? appInfo;

  const ProfilLoaded({
    this.sekolah,
    this.sekolahDariCache = false,
    this.sekolahError,
    this.perangkat = const [],
    this.perangkatTersedia = false,
    this.perangkatError,
    this.appInfo,
  });

  @override
  List<Object?> get props => [
    sekolah,
    sekolahDariCache,
    sekolahError,
    perangkat,
    perangkatTersedia,
    perangkatError,
    appInfo,
  ];
}

class ProfilError extends ProfilState {
  final String message;
  const ProfilError(this.message);

  @override
  List<Object?> get props => [message];
}
