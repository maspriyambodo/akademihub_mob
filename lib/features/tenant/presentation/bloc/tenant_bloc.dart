import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/tenant_entity.dart';
import '../../domain/usecases/tenant_usecases.dart';
import '../../../../core/config/tenant_config.dart';
import '../../../../core/storage/tenant_storage.dart';

part 'tenant_event.dart';
part 'tenant_state.dart';

class TenantBloc extends Bloc<TenantEvent, TenantState> {
  final ResolveTenantUseCase resolveTenant;
  final ListTenantsUseCase listTenants;
  final TenantStorage tenantStorage;

  TenantBloc({
    required this.resolveTenant,
    required this.listTenants,
    required this.tenantStorage,
  }) : super(TenantInitial()) {
    on<TenantLoadSaved>(_onLoadSaved);
    on<TenantResolveRequested>(_onResolveRequested);
    on<TenantSelected>(_onSelected);
    on<TenantCleared>(_onCleared);
    on<TenantListRequested>(_onListRequested);
  }

  void _onLoadSaved(TenantLoadSaved event, Emitter<TenantState> emit) {
    final saved = tenantStorage.getSavedTenant();
    if (saved != null) {
      emit(TenantActive(saved));
    } else {
      emit(TenantNotSelected());
    }
  }

  Future<void> _onResolveRequested(
    TenantResolveRequested event,
    Emitter<TenantState> emit,
  ) async {
    emit(TenantLoading());
    final result = await resolveTenant(event.identifier);
    if (result.isSuccess) {
      emit(TenantResolved(result.requireData));
    } else {
      emit(TenantError(result.requireFailure.message));
    }
  }

  Future<void> _onSelected(
    TenantSelected event,
    Emitter<TenantState> emit,
  ) async {
    final config = event.tenant.toConfig();
    await tenantStorage.saveTenant(config);
    emit(TenantActive(config));
  }

  Future<void> _onCleared(
    TenantCleared event,
    Emitter<TenantState> emit,
  ) async {
    await tenantStorage.clearTenant();
    emit(TenantNotSelected());
  }

  Future<void> _onListRequested(
    TenantListRequested event,
    Emitter<TenantState> emit,
  ) async {
    emit(TenantLoading());
    final result = await listTenants(query: event.query);
    if (result.isSuccess) {
      emit(TenantListLoaded(result.requireData));
    } else {
      emit(TenantError(result.requireFailure.message));
    }
  }
}
