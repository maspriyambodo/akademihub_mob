import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/rapor_detail_entity.dart';
import '../../domain/usecases/export_rapor_usecase.dart';
import '../../domain/usecases/get_rapor_detail_usecase.dart';

part 'rapor_detail_event.dart';
part 'rapor_detail_state.dart';

/// Bloc halaman detail rapor (rincian per mapel + unduh berkas).
class RaporDetailBloc extends Bloc<RaporDetailEvent, RaporDetailState> {
  final GetRaporDetailUseCase getRaporDetail;
  final ExportRaporUseCase exportRapor;

  int? _raporId;

  RaporDetailBloc({required this.getRaporDetail, required this.exportRapor})
    : super(RaporDetailInitial()) {
    on<RaporDetailLoadRequested>(_onLoad);
    on<RaporDetailRefreshRequested>(_onRefresh);
    on<RaporDetailExportRequested>(_onExport);
  }

  Future<void> _onLoad(
    RaporDetailLoadRequested event,
    Emitter<RaporDetailState> emit,
  ) async {
    _raporId = event.raporId;
    emit(RaporDetailLoading());
    await _fetchAndEmit(emit);
  }

  Future<void> _onRefresh(
    RaporDetailRefreshRequested event,
    Emitter<RaporDetailState> emit,
  ) async {
    if (_raporId == null) return;
    emit(RaporDetailLoading());
    await _fetchAndEmit(emit);
  }

  Future<void> _fetchAndEmit(Emitter<RaporDetailState> emit) async {
    final id = _raporId;
    if (id == null) {
      emit(const RaporDetailError('ID rapor tidak valid'));
      return;
    }

    final result = await getRaporDetail(id);
    if (result.isSuccess) {
      emit(RaporDetailLoaded(detail: result.requireData));
    } else {
      emit(RaporDetailError(result.requireFailure.message));
    }
  }

  Future<void> _onExport(
    RaporDetailExportRequested event,
    Emitter<RaporDetailState> emit,
  ) async {
    final current = state;
    if (current is! RaporDetailLoaded) return;
    if (current.exportStatus == RaporExportStatus.loading) return;

    emit(
      current.copyWith(
        exportStatus: RaporExportStatus.loading,
        clearExportPath: true,
        clearExportMessage: true,
      ),
    );

    final result = await exportRapor(event.siswaId);
    if (result.isSuccess) {
      emit(
        current.copyWith(
          exportStatus: RaporExportStatus.success,
          exportPath: result.requireData,
        ),
      );
    } else {
      emit(
        current.copyWith(
          exportStatus: RaporExportStatus.failure,
          exportMessage: result.requireFailure.message,
        ),
      );
    }
  }
}
