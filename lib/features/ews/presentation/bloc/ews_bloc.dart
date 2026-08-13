import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/ews_alert_entity.dart';
import '../../domain/usecases/get_ews_alerts_usecase.dart';
import '../../domain/usecases/resolve_ews_alert_usecase.dart';
import '../../domain/usecases/trigger_ews_check_usecase.dart';

part 'ews_event.dart';
part 'ews_state.dart';

class EwsBloc extends Bloc<EwsEvent, EwsState> {
  final GetEwsAlertsUseCase getAlerts;
  final ResolveEwsAlertUseCase resolveAlert;
  final TriggerEwsCheckUseCase triggerCheck;

  EwsBloc({
    required this.getAlerts,
    required this.resolveAlert,
    required this.triggerCheck,
  }) : super(const EwsInitial()) {
    on<EwsLoadRequested>(_onLoad);
    on<EwsRefreshRequested>(_onRefresh);
    on<EwsFilterChanged>(_onFilterChanged);
    on<EwsResolveRequested>(_onResolve);
    on<EwsTriggerCheckRequested>(_onTrigger);
  }

  Future<void> _onLoad(EwsLoadRequested event, Emitter<EwsState> emit) async {
    emit(
      EwsLoading(
        kategori: event.kategori,
        level: event.level,
        onlyUnresolved: event.onlyUnresolved,
      ),
    );
    await _fetch(
      emit,
      kategori: event.kategori,
      level: event.level,
      isResolved: event.onlyUnresolved == true ? false : null,
    );
  }

  Future<void> _onRefresh(
    EwsRefreshRequested event,
    Emitter<EwsState> emit,
  ) async {
    final current = state;
    if (current is! EwsLoaded) {
      emit(
        EwsLoading(
          kategori: current.kategori,
          level: current.level,
          onlyUnresolved: current.onlyUnresolved,
        ),
      );
    }
    await _fetch(
      emit,
      kategori: current.kategori,
      level: current.level,
      isResolved: current.onlyUnresolved == true ? false : null,
    );
  }

  Future<void> _onFilterChanged(
    EwsFilterChanged event,
    Emitter<EwsState> emit,
  ) async {
    emit(
      EwsLoading(
        kategori: event.kategori,
        level: event.level,
        onlyUnresolved: event.onlyUnresolved,
      ),
    );
    await _fetch(
      emit,
      kategori: event.kategori,
      level: event.level,
      isResolved: event.onlyUnresolved == true ? false : null,
    );
  }

  Future<void> _fetch(
    Emitter<EwsState> emit, {
    String? kategori,
    int? level,
    bool? isResolved,
  }) async {
    final result = await getAlerts(
      kategori: kategori,
      level: level,
      isResolved: isResolved,
    );
    if (isClosed) return;
    if (result.isSuccess) {
      emit(
        EwsLoaded(
          items: result.requireData,
          kategori: kategori,
          level: level,
          onlyUnresolved: onlyUnresolvedFrom(isResolved),
        ),
      );
    } else {
      emit(
        EwsError(
          result.requireFailure.message,
          kategori: kategori,
          level: level,
          onlyUnresolved: onlyUnresolvedFrom(isResolved),
        ),
      );
    }
  }

  bool? onlyUnresolvedFrom(bool? isResolved) {
    if (isResolved == false) return true;
    return null;
  }

  Future<void> _onResolve(
    EwsResolveRequested event,
    Emitter<EwsState> emit,
  ) async {
    final current = state;
    if (current is! EwsLoaded) return;

    final idx = current.items.indexWhere((e) => e.id == event.id);
    if (idx == -1) return;
    final previous = current.items[idx];

    final optimistic = [...current.items];
    optimistic[idx] = EwsAlertEntity(
      id: previous.id,
      siswaId: previous.siswaId,
      kategori: previous.kategori,
      level: previous.level,
      pesan: previous.pesan,
      dataPendukung: previous.dataPendukung,
      isResolved: true,
      resolvedAt: DateTime.now(),
      resolvedBy: previous.resolvedBy,
      createdAt: previous.createdAt,
      updatedAt: previous.updatedAt,
    );
    emit(
      EwsLoaded(
        items: optimistic,
        kategori: current.kategori,
        level: current.level,
        onlyUnresolved: current.onlyUnresolved,
        actionMessage: null,
      ),
    );

    final result = await resolveAlert(event.id);
    if (isClosed) return;
    if (result.isFailure) {
      final latest = state;
      if (latest is EwsLoaded) {
        final reverted = [...latest.items];
        final i = reverted.indexWhere((e) => e.id == event.id);
        if (i != -1) reverted[i] = previous;
        emit(
          EwsLoaded(
            items: reverted,
            kategori: latest.kategori,
            level: latest.level,
            onlyUnresolved: latest.onlyUnresolved,
            actionMessage: result.requireFailure.message,
          ),
        );
      }
    }
  }

  Future<void> _onTrigger(
    EwsTriggerCheckRequested event,
    Emitter<EwsState> emit,
  ) async {
    final current = state;
    final result = await triggerCheck(event.siswaId);
    if (isClosed) return;

    if (current is EwsLoaded) {
      emit(
        EwsLoaded(
          items: current.items,
          kategori: current.kategori,
          level: current.level,
          onlyUnresolved: current.onlyUnresolved,
          actionMessage: result.isSuccess
              ? 'Pengecekan EWS selesai dijalankan'
              : result.requireFailure.message,
        ),
      );
    } else if (result.isFailure) {
      emit(EwsError(result.requireFailure.message));
    } else {
      emit(
        const EwsLoaded(
          items: [],
          actionMessage: 'Pengecekan EWS selesai dijalankan',
        ),
      );
    }
  }
}
