part of 'ppdb_bloc.dart';

abstract class PpdbEvent extends Equatable {
  const PpdbEvent();

  @override
  List<Object?> get props => [];
}

class PpdbLoadRequested extends PpdbEvent {
  final String role;
  final bool bolehLihatPendaftar;
  final bool bolehLihatGelombang;

  const PpdbLoadRequested({
    required this.role,
    required this.bolehLihatPendaftar,
    required this.bolehLihatGelombang,
  });

  @override
  List<Object?> get props => [role, bolehLihatPendaftar, bolehLihatGelombang];
}

class PpdbRefreshRequested extends PpdbEvent {
  const PpdbRefreshRequested();
}

/// Muat ulang senyap (tanpa state Loading) — dipanggil saat kembali dari
/// halaman detail karena aksi di sana bisa mengubah status pendaftar.
class PpdbMuatUlangSenyap extends PpdbEvent {
  const PpdbMuatUlangSenyap();
}

class PpdbSearchChanged extends PpdbEvent {
  final String search;
  const PpdbSearchChanged(this.search);

  @override
  List<Object?> get props => [search];
}

class PpdbStatusFilterChanged extends PpdbEvent {
  final String? status;
  const PpdbStatusFilterChanged(this.status);

  @override
  List<Object?> get props => [status];
}

class PpdbGelombangFilterChanged extends PpdbEvent {
  final int? gelombangId;
  const PpdbGelombangFilterChanged(this.gelombangId);

  @override
  List<Object?> get props => [gelombangId];
}
