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

  const ProfilLoadRequested({
    required this.userId,
    this.bisaLihatSekolah = false,
    this.bisaLihatPerangkat = false,
  });

  @override
  List<Object?> get props => [userId, bisaLihatSekolah, bisaLihatPerangkat];
}

class ProfilRefreshRequested extends ProfilEvent {
  const ProfilRefreshRequested();
}
