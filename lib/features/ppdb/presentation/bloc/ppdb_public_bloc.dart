import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/ppdb_gelombang_entity.dart';
import '../../domain/entities/ppdb_public_entity.dart';
import '../../domain/repositories/ppdb_repository.dart';

class PpdbPublicState extends Equatable {
  final bool loading;
  final List<PpdbSekolahEntity> sekolah;
  final List<PpdbGelombangEntity> gelombang;
  final PpdbStatusPublikEntity? status;
  final PpdbPendaftaranPublikEntity? pendaftaran;
  final String? error;

  const PpdbPublicState({
    this.loading = false,
    this.sekolah = const [],
    this.gelombang = const [],
    this.status,
    this.pendaftaran,
    this.error,
  });

  PpdbPublicState copyWith({
    bool? loading,
    List<PpdbSekolahEntity>? sekolah,
    List<PpdbGelombangEntity>? gelombang,
    PpdbStatusPublikEntity? status,
    PpdbPendaftaranPublikEntity? pendaftaran,
    String? error,
    bool clearResult = false,
  }) => PpdbPublicState(
    loading: loading ?? this.loading,
    sekolah: sekolah ?? this.sekolah,
    gelombang: gelombang ?? this.gelombang,
    status: clearResult ? null : status ?? this.status,
    pendaftaran: clearResult ? null : pendaftaran ?? this.pendaftaran,
    error: error,
  );

  @override
  List<Object?> get props => [
    loading,
    sekolah,
    gelombang,
    status,
    pendaftaran,
    error,
  ];
}

sealed class PpdbPublicEvent {
  const PpdbPublicEvent();
}

class PpdbPublicStarted extends PpdbPublicEvent {
  const PpdbPublicStarted();
}

class PpdbPublicSekolahChanged extends PpdbPublicEvent {
  final int sekolahId;
  const PpdbPublicSekolahChanged(this.sekolahId);
}

class PpdbPublicStatusRequested extends PpdbPublicEvent {
  final String nomor;
  const PpdbPublicStatusRequested(this.nomor);
}

class PpdbPublicDaftarRequested extends PpdbPublicEvent {
  final Map<String, dynamic> data;
  const PpdbPublicDaftarRequested(this.data);
}

class PpdbPublicBloc extends Bloc<PpdbPublicEvent, PpdbPublicState> {
  final PpdbRepository _repository;

  PpdbPublicBloc(this._repository) : super(const PpdbPublicState()) {
    on<PpdbPublicStarted>(_started);
    on<PpdbPublicSekolahChanged>(_sekolahChanged);
    on<PpdbPublicStatusRequested>(_statusRequested);
    on<PpdbPublicDaftarRequested>(_daftarRequested);
  }

  Future<void> _started(
    PpdbPublicStarted event,
    Emitter<PpdbPublicState> emit,
  ) async {
    emit(state.copyWith(loading: true, clearResult: true));
    final result = await _repository.getSekolahPublik();
    if (result.isFailure) {
      emit(
        state.copyWith(loading: false, error: result.requireFailure.message),
      );
      return;
    }
    emit(state.copyWith(loading: false, sekolah: result.requireData));
  }

  Future<void> _sekolahChanged(
    PpdbPublicSekolahChanged event,
    Emitter<PpdbPublicState> emit,
  ) async {
    emit(state.copyWith(loading: true, gelombang: const [], clearResult: true));
    final result = await _repository.getGelombangPublik(event.sekolahId);
    if (result.isFailure) {
      emit(
        state.copyWith(loading: false, error: result.requireFailure.message),
      );
      return;
    }
    emit(state.copyWith(loading: false, gelombang: result.requireData));
  }

  Future<void> _statusRequested(
    PpdbPublicStatusRequested event,
    Emitter<PpdbPublicState> emit,
  ) async {
    await _run(
      emit,
      _repository.cekStatusPublik(event.nomor),
      (value) => state.copyWith(loading: false, status: value),
    );
  }

  Future<void> _daftarRequested(
    PpdbPublicDaftarRequested event,
    Emitter<PpdbPublicState> emit,
  ) async {
    await _run(
      emit,
      _repository.daftarPublik(event.data),
      (value) => state.copyWith(loading: false, pendaftaran: value),
    );
  }

  Future<void> _run<T>(
    Emitter<PpdbPublicState> emit,
    Future<Result<T>> request,
    PpdbPublicState Function(T value) success,
  ) async {
    emit(state.copyWith(loading: true, clearResult: true));
    final result = await request;
    if (result.isFailure) {
      emit(
        state.copyWith(loading: false, error: result.requireFailure.message),
      );
      return;
    }
    emit(success(result.requireData));
  }
}
