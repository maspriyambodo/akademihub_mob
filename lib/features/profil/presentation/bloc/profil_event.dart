part of 'profil_bloc.dart';

abstract class ProfilEvent extends Equatable {
  const ProfilEvent();

  @override
  List<Object?> get props => [];
}

class ProfilLoadRequested extends ProfilEvent {
  final int userId;

  /// Punya permission `sekolah.view` → boleh memanggil endpoint sekolah.
  final bool bisaLihatSekolah;

  /// Punya permission `users.view` → boleh melihat daftar perangkat login.
  final bool bisaLihatPerangkat;

  /// Fallback metadata sekolah dari sesi tenant aktif jika user tidak memiliki izin sekolah.view.
  final SekolahEntity? fallbackSekolah;

  const ProfilLoadRequested({
    required this.userId,
    this.bisaLihatSekolah = false,
    this.bisaLihatPerangkat = false,
    this.fallbackSekolah,
  });

  @override
  List<Object?> get props => [
    userId,
    bisaLihatSekolah,
    bisaLihatPerangkat,
    fallbackSekolah,
  ];
}

class ProfilRefreshRequested extends ProfilEvent {
  const ProfilRefreshRequested();
}
