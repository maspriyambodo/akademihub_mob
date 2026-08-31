import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/dashboard_entity.dart';
import '../../domain/usecases/get_dashboard_usecase.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final GetDashboardDataUseCase _getDashboardData;

  DashboardBloc(this._getDashboardData) : super(DashboardInitial()) {
    on<DashboardLoadRequested>(_onLoad);
    on<DashboardRefreshRequested>(_onRefresh);
  }

  Future<void> _onLoad(
    DashboardLoadRequested event,
    Emitter<DashboardState> emit,
  ) async {
    emit(DashboardLoading());
    try {
      final data = await _getDashboardData();
      emit(DashboardLoaded(data));
    } on AppException catch (error) {
      emit(DashboardError(error.message));
    } catch (_) {
      emit(
        DashboardError('Terjadi kesalahan tidak terduga. Silakan coba lagi.'),
      );
    }
  }

  Future<void> _onRefresh(
    DashboardRefreshRequested event,
    Emitter<DashboardState> emit,
  ) async {
    try {
      final data = await _getDashboardData();
      emit(DashboardLoaded(data));
    } on AppException catch (error) {
      emit(DashboardError(error.message));
    } catch (_) {
      emit(
        DashboardError('Terjadi kesalahan tidak terduga. Silakan coba lagi.'),
      );
    }
  }
}
