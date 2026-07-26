part of 'organisasi_bloc.dart';

/// Filter status organisasi di daftar.
enum StatusOrganisasiFilter { aktif, semua }

abstract class OrganisasiState extends Equatable {
  const OrganisasiState();

  @override
  List<Object?> get props => [];
}

class OrganisasiInitial extends OrganisasiState {}

class OrganisasiLoading extends OrganisasiState {}

/// User tidak punya izin `organisasi.view` (mis. role guru).
class OrganisasiForbidden extends OrganisasiState {
  final String message;
  const OrganisasiForbidden(this.message);

  @override
  List<Object?> get props => [message];
}

class OrganisasiLoaded extends OrganisasiState {
  final List<OrganisasiEntity> semua;
  final String search;
  final StatusOrganisasiFilter filterStatus;

  /// Tahun `periode_mulai` terpilih; null = semua periode.
  final int? filterPeriode;

  const OrganisasiLoaded({
    required this.semua,
    this.search = '',
    this.filterStatus = StatusOrganisasiFilter.aktif,
    this.filterPeriode,
  });

  /// Daftar tahun periode (distinct `periode_mulai`, terbaru dulu)
  /// untuk chip filter.
  List<int> get daftarPeriode {
    final tahun = <int>{
      for (final o in semua)
        if (o.periodeMulai != null) o.periodeMulai!,
    }.toList()..sort((a, b) => b.compareTo(a));
    return tahun;
  }

  /// Daftar organisasi setelah filter status, periode, dan pencarian.
  List<OrganisasiEntity> get tampil {
    final kueri = search.trim().toLowerCase();
    return semua.where((o) {
      if (filterStatus == StatusOrganisasiFilter.aktif && !o.isAktif) {
        return false;
      }
      if (filterPeriode != null && o.periodeMulai != filterPeriode) {
        return false;
      }
      if (kueri.isEmpty) return true;
      return o.nama.toLowerCase().contains(kueri) ||
          (o.kode ?? '').toLowerCase().contains(kueri) ||
          (o.pembinaNama ?? '').toLowerCase().contains(kueri);
    }).toList();
  }

  OrganisasiLoaded copyWith({
    List<OrganisasiEntity>? semua,
    String? search,
    StatusOrganisasiFilter? filterStatus,
    int? filterPeriode,
    bool setPeriode = false,
  }) {
    return OrganisasiLoaded(
      semua: semua ?? this.semua,
      search: search ?? this.search,
      filterStatus: filterStatus ?? this.filterStatus,
      filterPeriode: setPeriode ? filterPeriode : this.filterPeriode,
    );
  }

  @override
  List<Object?> get props => [semua, search, filterStatus, filterPeriode];
}

class OrganisasiError extends OrganisasiState {
  final String message;
  const OrganisasiError(this.message);

  @override
  List<Object?> get props => [message];
}
