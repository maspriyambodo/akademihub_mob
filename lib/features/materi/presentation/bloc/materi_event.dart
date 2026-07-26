part of 'materi_bloc.dart';

abstract class MateriEvent extends Equatable {
  const MateriEvent();

  @override
  List<Object?> get props => [];
}

class MateriLoadRequested extends MateriEvent {
  final String role;

  /// `profile['id']` bila role siswa.
  final int? siswaId;

  /// `profile['kelas']['id']` bila role siswa — wajib untuk pencatatan log.
  final int? kelasId;

  /// `profile['id']` bila role guru (id `mst_guru`).
  final int? guruId;

  /// Id `mst_guru_mapel` bila tersedia di profil (biasanya tidak ada).
  final int? guruMapelId;

  const MateriLoadRequested({
    required this.role,
    this.siswaId,
    this.kelasId,
    this.guruId,
    this.guruMapelId,
  });

  @override
  List<Object?> get props => [role, siswaId, kelasId, guruId, guruMapelId];
}

class MateriRefreshRequested extends MateriEvent {
  const MateriRefreshRequested();
}

/// Pencarian judul/deskripsi/mapel/guru — dijalankan client-side.
class MateriSearchChanged extends MateriEvent {
  final String query;
  const MateriSearchChanged(this.query);

  @override
  List<Object?> get props => [query];
}

/// Filter berdasarkan nama mata pelajaran; null = semua.
class MateriMapelFilterChanged extends MateriEvent {
  final String? mapel;
  const MateriMapelFilterChanged(this.mapel);

  @override
  List<Object?> get props => [mapel];
}
