part of 'jadwal_bloc.dart';

abstract class JadwalEvent extends Equatable {
  const JadwalEvent();
  @override
  List<Object?> get props => [];
}

/// Muat jadwal sesuai role.
/// - siswa / wali : butuh [kelasId] (dari `user.profile['kelas']['id']`)
/// - guru         : butuh [guruId] (dari `user.profile['id']`), difilter client-side
/// - admin        : tanpa keduanya, memakai endpoint index
class JadwalLoadRequested extends JadwalEvent {
  final String role;
  final int? kelasId;
  final int? guruId;

  /// Kode hari awal yang dipilih ('MON'..'SUN'). Bila null dipakai hari ini.
  final String? hari;

  const JadwalLoadRequested({
    required this.role,
    this.kelasId,
    this.guruId,
    this.hari,
  });

  @override
  List<Object?> get props => [role, kelasId, guruId, hari];
}

/// Ganti hari yang ditampilkan (difilter dari cache, tanpa request baru).
class JadwalHariChanged extends JadwalEvent {
  final String hari;
  const JadwalHariChanged(this.hari);

  @override
  List<Object?> get props => [hari];
}

/// Muat ulang data (pull-to-refresh / tombol coba lagi).
class JadwalRefreshRequested extends JadwalEvent {
  const JadwalRefreshRequested();
}
