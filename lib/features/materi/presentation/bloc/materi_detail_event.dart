part of 'materi_detail_bloc.dart';

abstract class MateriDetailEvent extends Equatable {
  const MateriDetailEvent();

  @override
  List<Object?> get props => [];
}

class MateriDetailLoadRequested extends MateriDetailEvent {
  final int materiId;

  /// Data materi dari daftar; dipakai sebagai tampilan awal sekaligus
  /// cadangan bila endpoint detail gagal.
  final MateriEntity? awal;

  /// Ambil juga statistik pembaca (hanya guru/admin).
  final bool denganStatistik;

  const MateriDetailLoadRequested({
    required this.materiId,
    this.awal,
    this.denganStatistik = false,
  });

  @override
  List<Object?> get props => [materiId, awal, denganStatistik];
}

class MateriDetailRefreshRequested extends MateriDetailEvent {
  const MateriDetailRefreshRequested();
}

/// Mulai pencatatan log akses (siswa). Fire-and-forget di bloc.
class MateriDetailAksesDiminta extends MateriDetailEvent {
  final int materiId;
  final int siswaId;
  final int kelasId;

  const MateriDetailAksesDiminta({
    required this.materiId,
    required this.siswaId,
    required this.kelasId,
  });

  @override
  List<Object?> get props => [materiId, siswaId, kelasId];
}

/// Kirim durasi baca saat meninggalkan halaman.
class MateriDetailDurasiDikirim extends MateriDetailEvent {
  final int durasiDetik;

  const MateriDetailDurasiDikirim({required this.durasiDetik});

  @override
  List<Object?> get props => [durasiDetik];
}
