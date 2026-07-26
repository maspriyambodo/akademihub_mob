part of 'ekstrakurikuler_detail_bloc.dart';

abstract class EkstrakurikulerDetailEvent extends Equatable {
  const EkstrakurikulerDetailEvent();
  @override
  List<Object?> get props => [];
}

class EkstrakurikulerDetailLoadRequested extends EkstrakurikulerDetailEvent {
  final int ekstrakurikulerId;

  /// `profile['id']` bila role siswa — dipakai untuk `check-status`.
  final int? siswaId;

  /// `ekstrakurikuler.pendaftaran.view`.
  final bool canViewPendaftaran;

  /// Kesimpulan awal dari tab "Ekskul Saya"; dipakai bila `check-status`
  /// tidak bisa dipanggil (izin kurang) atau gagal.
  final bool sudahTerdaftarDariDaftar;

  const EkstrakurikulerDetailLoadRequested({
    required this.ekstrakurikulerId,
    this.siswaId,
    this.canViewPendaftaran = false,
    this.sudahTerdaftarDariDaftar = false,
  });

  @override
  List<Object?> get props => [
    ekstrakurikulerId,
    siswaId,
    canViewPendaftaran,
    sudahTerdaftarDariDaftar,
  ];
}

class EkstrakurikulerDetailRefreshRequested extends EkstrakurikulerDetailEvent {
  const EkstrakurikulerDetailRefreshRequested();
}
