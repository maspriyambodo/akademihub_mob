import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/forum_entity.dart';
import '../../domain/usecases/get_forum_usecase.dart';

part 'forum_detail_event.dart';
part 'forum_detail_state.dart';

/// Bloc halaman detail satu post forum.
///
/// Aksi tulis (ubah/hapus) tetap ditangani `ForumBloc` supaya daftar dan
/// detail tidak menyimpan dua sumber kebenaran.
class ForumDetailBloc extends Bloc<ForumDetailEvent, ForumDetailState> {
  final GetForumDetailUseCase getForumDetail;

  ForumDetailBloc({required this.getForumDetail})
    : super(ForumDetailInitial()) {
    on<ForumDetailLoadRequested>(_onLoad);
    on<ForumDetailRefreshRequested>(_onRefresh);
  }

  int? _id;

  Future<void> _onLoad(
    ForumDetailLoadRequested event,
    Emitter<ForumDetailState> emit,
  ) async {
    _id = event.id;
    emit(ForumDetailLoading());
    await _ambil(emit);
  }

  Future<void> _onRefresh(
    ForumDetailRefreshRequested event,
    Emitter<ForumDetailState> emit,
  ) async {
    await _ambil(emit);
  }

  Future<void> _ambil(Emitter<ForumDetailState> emit) async {
    final id = _id;
    if (id == null) {
      emit(const ForumDetailError('Topik tidak valid'));
      return;
    }

    final result = await getForumDetail(id);
    if (result.isFailure) {
      emit(ForumDetailError(result.requireFailure.message));
      return;
    }
    emit(ForumDetailLoaded(result.requireData));
  }
}
