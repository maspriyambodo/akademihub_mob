part of 'kalender_bloc.dart';

abstract class KalenderEvent extends Equatable {
  const KalenderEvent();

  @override
  List<Object?> get props => [];
}

/// Muat pertama kali.
///
/// [bolehLihatKalender] berasal dari `user.hasPermission('kalender-akademik.view')`.
/// Bila false, bloc langsung mengeluarkan [KalenderForbidden] tanpa memanggil
/// API — endpoint kalender ada di grup `admin` dan akan membalas 403.
class KalenderLoadRequested extends KalenderEvent {
  final String role;
  final bool bolehLihatKalender;
  final bool bolehLihatHarian;
  final bool bolehLihatTipe;
  final int bulan;
  final int tahun;

  const KalenderLoadRequested({
    required this.role,
    required this.bolehLihatKalender,
    this.bolehLihatHarian = true,
    this.bolehLihatTipe = true,
    required this.bulan,
    required this.tahun,
  });

  @override
  List<Object?> get props => [
    role,
    bolehLihatKalender,
    bolehLihatHarian,
    bolehLihatTipe,
    bulan,
    tahun,
  ];
}

/// Ganti bulan/tahun yang ditampilkan (difilter dari cache, tanpa request baru).
class KalenderMonthChanged extends KalenderEvent {
  final int bulan;
  final int tahun;

  const KalenderMonthChanged({required this.bulan, required this.tahun});

  @override
  List<Object?> get props => [bulan, tahun];
}

/// Filter berdasarkan tipe/kategori. `null` = semua tipe.
class KalenderTipeFilterChanged extends KalenderEvent {
  final int? tipeId;

  const KalenderTipeFilterChanged(this.tipeId);

  @override
  List<Object?> get props => [tipeId];
}

class KalenderRefreshRequested extends KalenderEvent {
  const KalenderRefreshRequested();
}
