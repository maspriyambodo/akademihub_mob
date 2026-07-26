part of 'ekstrakurikuler_bloc.dart';

abstract class EkstrakurikulerEvent extends Equatable {
  const EkstrakurikulerEvent();
  @override
  List<Object?> get props => [];
}

class EkstrakurikulerLoadRequested extends EkstrakurikulerEvent {
  /// 'siswa' | 'guru' | 'wali' | 'admin' (sudah dinormalisasi lowercase).
  final String role;

  /// `profile['id']` bila role siswa.
  final int? siswaId;

  /// `profile['id']` bila role guru (id `mst_guru`).
  final int? guruId;

  /// `ekstrakurikuler.pendaftaran.manage`.
  final bool canManagePendaftaran;

  /// `ekstrakurikuler.pendaftaran.view`.
  final bool canViewPendaftaran;

  const EkstrakurikulerLoadRequested({
    required this.role,
    this.siswaId,
    this.guruId,
    this.canManagePendaftaran = false,
    this.canViewPendaftaran = false,
  });

  @override
  List<Object?> get props => [
    role,
    siswaId,
    guruId,
    canManagePendaftaran,
    canViewPendaftaran,
  ];
}

class EkstrakurikulerRefreshRequested extends EkstrakurikulerEvent {
  const EkstrakurikulerRefreshRequested();
}

/// Beralih antara daftar ekskul aktif saja dan seluruh ekskul.
class EkstrakurikulerSumberChanged extends EkstrakurikulerEvent {
  final EkskulSumber sumber;
  const EkstrakurikulerSumberChanged(this.sumber);

  @override
  List<Object?> get props => [sumber];
}

/// Pencarian disaring di sisi klien (lihat catatan di datasource).
class EkstrakurikulerSearchChanged extends EkstrakurikulerEvent {
  final String keyword;
  const EkstrakurikulerSearchChanged(this.keyword);

  @override
  List<Object?> get props => [keyword];
}

class EkstrakurikulerDaftarRequested extends EkstrakurikulerEvent {
  final int ekstrakurikulerId;
  const EkstrakurikulerDaftarRequested(this.ekstrakurikulerId);

  @override
  List<Object?> get props => [ekstrakurikulerId];
}

class EkstrakurikulerKeluarRequested extends EkstrakurikulerEvent {
  /// Id baris `trx_ekstrakurikuler_siswa`, bukan id ekskul.
  final int pendaftaranId;
  const EkstrakurikulerKeluarRequested(this.pendaftaranId);

  @override
  List<Object?> get props => [pendaftaranId];
}
