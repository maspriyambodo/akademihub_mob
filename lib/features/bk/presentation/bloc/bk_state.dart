part of 'bk_bloc.dart';

abstract class BkState extends Equatable {
  const BkState();

  @override
  List<Object?> get props => [];
}

class BkInitial extends BkState {}

class BkLoading extends BkState {}

/// Role login tidak punya permission `bk-kasus.view`.
class BkNoAccess extends BkState {
  final String message;
  const BkNoAccess(this.message);

  @override
  List<Object?> get props => [message];
}

class BkLoaded extends BkState {
  /// Daftar setelah filter status + pencarian client-side.
  final List<BkKasusEntity> items;

  /// Jumlah seluruh kasus sebelum difilter.
  final int totalSemua;

  /// Jumlah kasus per label status (lowercase) — untuk chip filter.
  final Map<String, int> hitungStatus;

  final String? filterStatus;
  final String search;
  final String role;
  final bool canCreate;
  final int revisi;

  const BkLoaded({
    required this.items,
    required this.totalSemua,
    required this.hitungStatus,
    required this.filterStatus,
    required this.search,
    required this.role,
    required this.canCreate,
    required this.revisi,
  });

  bool get adaFilterAktif => filterStatus != null || search.isNotEmpty;

  /// Nama siswa lain tidak boleh tampil untuk role siswa (data sensitif).
  bool get tampilkanNamaSiswa => role != 'siswa';

  @override
  List<Object?> get props => [
    items,
    totalSemua,
    hitungStatus,
    filterStatus,
    search,
    role,
    canCreate,
    revisi,
  ];
}

class BkError extends BkState {
  final String message;
  const BkError(this.message);

  @override
  List<Object?> get props => [message];
}
