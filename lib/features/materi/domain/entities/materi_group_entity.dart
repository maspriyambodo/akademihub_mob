import 'package:equatable/equatable.dart';

import 'materi_entity.dart';

/// Kelompok materi per mata pelajaran (dipakai tampilan siswa/wali).
class MateriGroupEntity extends Equatable {
  /// Id `mst_mapel`; null bila relasi `guru_mapel.mapel` tidak dimuat backend.
  final int? mapelId;

  final String mapelLabel;
  final List<MateriEntity> items;

  const MateriGroupEntity({
    this.mapelId,
    required this.mapelLabel,
    required this.items,
  });

  int get total => items.length;

  @override
  List<Object?> get props => [mapelId, mapelLabel, items];
}
