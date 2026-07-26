part of 'bk_bloc.dart';

abstract class BkEvent extends Equatable {
  const BkEvent();

  @override
  List<Object?> get props => [];
}

class BkLoadRequested extends BkEvent {
  /// Role yang SUDAH dinormalisasi ('siswa' | 'guru' | 'wali' | 'admin' | ...).
  final String role;

  /// `profile['id']` — id siswa untuk role siswa, id guru untuk role guru.
  final int? profileId;

  final bool canView;
  final bool canCreate;

  const BkLoadRequested({
    required this.role,
    this.profileId,
    required this.canView,
    required this.canCreate,
  });

  @override
  List<Object?> get props => [role, profileId, canView, canCreate];
}

class BkRefreshRequested extends BkEvent {
  const BkRefreshRequested();
}

/// Filter status client-side ('dibuka'/'proses'/'selesai'/'dirujuk');
/// mengirim status yang sama dengan filter aktif akan menghapus filter.
class BkStatusFilterChanged extends BkEvent {
  final String? status;
  const BkStatusFilterChanged(this.status);

  @override
  List<Object?> get props => [status];
}

class BkSearchChanged extends BkEvent {
  final String search;
  const BkSearchChanged(this.search);

  @override
  List<Object?> get props => [search];
}
