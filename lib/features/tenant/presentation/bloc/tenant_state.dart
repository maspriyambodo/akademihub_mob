part of 'tenant_bloc.dart';

abstract class TenantState extends Equatable {
  @override
  List<Object?> get props => [];
}

class TenantInitial extends TenantState {}

/// Sedang loading (resolve / list)
class TenantLoading extends TenantState {}

/// Belum ada tenant dipilih
class TenantNotSelected extends TenantState {}

/// Resolve berhasil — menunggu konfirmasi user
class TenantResolved extends TenantState {
  final TenantEntity tenant;
  TenantResolved(this.tenant);

  @override
  List<Object?> get props => [tenant];
}

/// Tenant sudah dipilih dan aktif
class TenantActive extends TenantState {
  final TenantConfig config;
  TenantActive(this.config);

  @override
  List<Object?> get props => [config];
}

/// Daftar tenant berhasil dimuat
class TenantListLoaded extends TenantState {
  final List<TenantEntity> tenants;
  TenantListLoaded(this.tenants);

  @override
  List<Object?> get props => [tenants];
}

class TenantError extends TenantState {
  final String message;
  TenantError(this.message);

  @override
  List<Object?> get props => [message];
}
