part of 'tugas_bloc.dart';

abstract class TugasState extends Equatable {
  const TugasState();
  @override
  List<Object?> get props => [];
}

class TugasInitial extends TugasState {}

class TugasLoading extends TugasState {}

class TugasLoaded extends TugasState {
  /// Item sesuai filter aktif (untuk daftar).
  final List<TugasItemEntity> items;

  /// Seluruh item tanpa filter (dipakai halaman detail).
  final List<TugasItemEntity> allItems;

  final int totalSemua;
  final int totalBelum;
  final int totalSudah;
  final TugasFilter filter;
  final String role;
  final int? siswaId;

  const TugasLoaded({
    required this.items,
    required this.allItems,
    required this.totalSemua,
    required this.totalBelum,
    required this.totalSudah,
    required this.filter,
    required this.role,
    this.siswaId,
  });

  TugasItemEntity? itemById(int tugasId) {
    for (final item in allItems) {
      if (item.tugas.id == tugasId) return item;
    }
    return null;
  }

  bool get isSiswaMode => role == 'siswa';
  bool get isGuruMode => role == 'guru';
  bool get isWaliMode => role == 'wali';

  /// Hanya siswa (dengan id profil) yang boleh mengumpulkan.
  bool get canSubmit => isSiswaMode && siswaId != null;

  @override
  List<Object?> get props => [
    items,
    allItems,
    totalSemua,
    totalBelum,
    totalSudah,
    filter,
    role,
    siswaId,
  ];
}

class TugasError extends TugasState {
  final String message;
  const TugasError(this.message);

  @override
  List<Object?> get props => [message];
}

/// State transien untuk feedback SnackBar setelah aksi berhasil.
class TugasActionSuccess extends TugasState {
  final String message;
  const TugasActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

/// State transien untuk feedback SnackBar setelah aksi gagal.
class TugasActionFailure extends TugasState {
  final String message;
  const TugasActionFailure(this.message);

  @override
  List<Object?> get props => [message];
}
