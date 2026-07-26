part of 'materi_bloc.dart';

abstract class MateriState extends Equatable {
  const MateriState();

  @override
  List<Object?> get props => [];
}

class MateriInitial extends MateriState {}

class MateriLoading extends MateriState {}

class MateriLoaded extends MateriState {
  /// Materi sesuai filter aktif (daftar datar).
  final List<MateriEntity> items;

  /// `items` yang sudah dikelompokkan per mata pelajaran.
  final List<MateriGroupEntity> groups;

  /// Seluruh materi tanpa filter.
  final List<MateriEntity> allItems;

  /// Materi terpopuler (kosong untuk siswa/wali atau bila endpoint gagal).
  final List<MateriPopulerEntity> populer;

  final List<String> opsiMapel;
  final String? mapelTerpilih;
  final String search;

  /// True bila relasi mapel terbaca dan ada lebih dari satu mapel.
  final bool dikelompokkan;

  final String role;
  final int? siswaId;
  final int? kelasId;

  const MateriLoaded({
    required this.items,
    required this.groups,
    required this.allItems,
    required this.populer,
    required this.opsiMapel,
    this.mapelTerpilih,
    required this.search,
    required this.dikelompokkan,
    required this.role,
    this.siswaId,
    this.kelasId,
  });

  bool get isSiswaMode => role == 'siswa';
  bool get isGuruMode => role == 'guru';
  bool get isWaliMode => role == 'wali';
  bool get isAdminMode => role == 'admin';

  /// Statistik pembaca hanya relevan (dan diizinkan) untuk guru/admin.
  bool get bolehLihatStatistik => isGuruMode || isAdminMode;

  /// Log akses hanya dicatat untuk siswa yang id & kelasnya diketahui.
  bool get bisaCatatAkses => isSiswaMode && siswaId != null && kelasId != null;

  int get totalSemua => allItems.length;
  int get totalTampil => items.length;

  bool get adaFilterAktif => search.trim().isNotEmpty || mapelTerpilih != null;

  MateriEntity? itemById(int id) {
    for (final m in allItems) {
      if (m.id == id) return m;
    }
    return null;
  }

  @override
  List<Object?> get props => [
    items,
    groups,
    allItems,
    populer,
    opsiMapel,
    mapelTerpilih,
    search,
    dikelompokkan,
    role,
    siswaId,
    kelasId,
  ];
}

class MateriError extends MateriState {
  final String message;
  const MateriError(this.message);

  @override
  List<Object?> get props => [message];
}
