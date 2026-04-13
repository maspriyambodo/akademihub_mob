part of 'tenant_bloc.dart';

abstract class TenantEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

/// Cek apakah ada tenant tersimpan di storage
class TenantLoadSaved extends TenantEvent {}

/// User menginput kode/subdomain sekolah dan menekan cari
class TenantResolveRequested extends TenantEvent {
  final String identifier;
  TenantResolveRequested(this.identifier);

  @override
  List<Object?> get props => [identifier];
}

/// User memilih sekolah dari hasil resolve/list
class TenantSelected extends TenantEvent {
  final TenantEntity tenant;
  TenantSelected(this.tenant);

  @override
  List<Object?> get props => [tenant.identifier];
}

/// User logout dan ingin ganti sekolah
class TenantCleared extends TenantEvent {}

/// Muat daftar sekolah (opsional, untuk search dropdown)
class TenantListRequested extends TenantEvent {
  final String? query;
  TenantListRequested({this.query});

  @override
  List<Object?> get props => [query];
}
