import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../../../core/storage/answer_outbox.dart';
import '../../domain/entities/tmb_hasil_entity.dart';
import '../../domain/entities/tmb_jawaban_entity.dart';
import '../../domain/entities/tmb_pertanyaan_entity.dart';
import '../../domain/entities/tmb_peserta_entity.dart';
import '../../domain/entities/tmb_tes_entity.dart';
import '../../domain/repositories/tmb_repository.dart';
import '../datasources/tmb_remote_datasource.dart';

class TmbRepositoryImpl implements TmbRepository {
  final TmbRemoteDataSource _remote;
  final AnswerOutbox _outbox;

  const TmbRepositoryImpl(this._remote, this._outbox);

  @override
  Future<Result<List<TmbTesEntity>>> getTesList() async {
    try {
      final models = await _remote.getTesList();
      return success(models.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      return fail(_mapDio(e));
    } on AppException catch (e) {
      return fail(_map(e));
    }
  }

  @override
  Future<Result<List<TmbTesEntity>>> getTesByKelas(int kelasId) async {
    try {
      final models = await _remote.getTesByKelas(kelasId);
      return success(models.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      return fail(_mapDio(e));
    } on AppException catch (e) {
      return fail(_map(e));
    }
  }

  @override
  Future<Result<List<TmbPertanyaanEntity>>> getPertanyaan(
    int tesId, {
    required bool viaTesDetail,
  }) async {
    try {
      final models = viaTesDetail
          ? await _remote.getPertanyaanViaTesDetail(tesId)
          : await _remote.getPertanyaanByTes(tesId);
      return success(models.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      return fail(_mapDio(e));
    } on AppException catch (e) {
      return fail(_map(e));
    }
  }

  @override
  Future<Result<List<TmbPesertaEntity>>> getPesertaBySiswa(int siswaId) async {
    try {
      final models = await _remote.getPesertaBySiswa(siswaId);
      return success(models.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      return fail(_mapDio(e));
    } on AppException catch (e) {
      return fail(_map(e));
    }
  }

  @override
  Future<Result<List<TmbPesertaEntity>>> getPesertaByTes(int tesId) async {
    try {
      final models = await _remote.getPesertaByTes(tesId);
      return success(models.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      return fail(_mapDio(e));
    } on AppException catch (e) {
      return fail(_map(e));
    }
  }

  @override
  Future<Result<TmbPesertaEntity>> daftarPeserta({
    required int tesId,
    required int siswaId,
  }) async {
    try {
      final model = await _remote.daftarPeserta(tesId: tesId, siswaId: siswaId);
      return success(model.toEntity());
    } on DioException catch (e) {
      return fail(_mapDio(e));
    } on AppException catch (e) {
      return fail(_map(e));
    }
  }

  @override
  Future<Result<TmbPesertaEntity>> mulaiTes(int pesertaId) async {
    try {
      final model = await _remote.mulaiTes(pesertaId);
      return success(model.toEntity());
    } on DioException catch (e) {
      return fail(_mapDio(e));
    } on AppException catch (e) {
      return fail(_map(e));
    }
  }

  @override
  Future<Result<TmbPesertaEntity>> selesaikanTes(int pesertaId) async {
    try {
      await _flush(pesertaId);
      if (_outbox.pending('tmb', pesertaId).isNotEmpty) {
        return fail(
          const NetworkFailure(
            'Jawaban belum tersinkron. Hubungkan internet lalu coba lagi.',
          ),
        );
      }
      final result = (await _remote.selesaikanTes(pesertaId)).toEntity();
      await _outbox.clearSession('tmb', pesertaId);
      return success(result);
    } on DioException catch (e) {
      return fail(_mapDio(e));
    } on AppException catch (e) {
      return fail(_map(e));
    }
  }

  @override
  Future<Result<TmbJawabanEntity>> kirimJawaban({
    required int pesertaId,
    required int pertanyaanId,
    int? opsiId,
    String? jawabanTeks,
  }) async {
    final payload = <String, dynamic>{
      'peserta_id': pesertaId,
      'pertanyaan_id': pertanyaanId,
      'opsi_id': opsiId,
      'jawaban_teks': jawabanTeks,
    };
    final operation = await _outbox.enqueue(
      module: 'tmb',
      sessionId: pesertaId,
      questionId: pertanyaanId,
      payload: payload,
    );
    try {
      final model = await _remote.kirimJawaban(
        pesertaId: pesertaId,
        pertanyaanId: pertanyaanId,
        opsiId: opsiId,
        jawabanTeks: jawabanTeks,
      );
      await _outbox.acknowledge(operation);
      return success(model.toEntity());
    } on DioException catch (e) {
      final failure = _mapDio(e);
      if (failure is NetworkFailure || failure is AuthFailure) {
        return success(_localAnswer(payload));
      }
      return fail(failure);
    } on AppException catch (e) {
      return fail(_map(e));
    }
  }

  @override
  Future<Result<List<TmbJawabanEntity>>> getJawabanByPeserta(
    int pesertaId,
  ) async {
    try {
      await _flush(pesertaId);
      final models = await _remote.getJawabanByPeserta(pesertaId);
      final answers = {
        for (final model in models) model.pertanyaanId: model.toEntity(),
      };
      for (final operation in _outbox.pending('tmb', pesertaId)) {
        answers[operation.questionId] = _localAnswer(operation.payload);
      }
      return success(answers.values.toList());
    } on DioException catch (e) {
      return fail(_mapDio(e));
    } on AppException catch (e) {
      return fail(_map(e));
    }
  }

  TmbJawabanEntity _localAnswer(Map<String, dynamic> payload) =>
      TmbJawabanEntity(
        id: 0,
        pesertaId: (payload['peserta_id'] as num).toInt(),
        pertanyaanId: (payload['pertanyaan_id'] as num).toInt(),
        opsiId: (payload['opsi_id'] as num?)?.toInt(),
        jawabanTeks: payload['jawaban_teks']?.toString(),
      );

  Future<void> _flush(int pesertaId) async {
    for (final operation in _outbox.pending('tmb', pesertaId)) {
      try {
        // ponytail: backoff caps at ~8s; upgrade to isolate worker if needed
        if (operation.retryCount > 0) {
          final delay = Duration(
            milliseconds: 500 * (1 << operation.retryCount.clamp(0, 4)),
          );
          await Future<void>.delayed(delay);
        }
        final payload = operation.payload;
        await _remote.kirimJawaban(
          pesertaId: pesertaId,
          pertanyaanId: operation.questionId,
          opsiId: (payload['opsi_id'] as num?)?.toInt(),
          jawabanTeks: payload['jawaban_teks']?.toString(),
        );
        await _outbox.acknowledge(operation);
      } on DioException catch (e) {
        final code = e.response?.statusCode ?? 0;
        if (code >= 400 && code < 500 && code != 401 && code != 408 && code != 429) {
          await _outbox.acknowledge(operation);
        } else {
          await _outbox.recordRetry(operation);
        }
        return;
      } on Object {
        await _outbox.recordRetry(operation);
        return;
      }
    }
  }

  @override
  Future<Result<List<TmbHasilEntity>>> getHasilByPeserta(int pesertaId) async {
    try {
      final models = await _remote.getHasilByPeserta(pesertaId);
      return success(models.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      return fail(_mapDio(e));
    } on AppException catch (e) {
      return fail(_map(e));
    }
  }

  /// 403 tidak dipetakan khusus oleh `mapDioException` (jatuh ke
  /// ServerException), padahal itu kasus umum di modul ini karena setiap
  /// endpoint dilindungi PermissionMiddleware.
  Failure _mapDio(DioException e) {
    if (e.response?.statusCode == 403) {
      final data = e.response?.data;
      final pesan = data is Map ? data['message']?.toString() : null;
      return TmbAccessFailure(
        pesan == null || pesan.trim().isEmpty
            ? 'Anda tidak memiliki izin mengakses tes minat bakat'
            : pesan,
      );
    }
    return _map(mapDioException(e));
  }

  Failure _map(AppException e) {
    if (e is NetworkException) return NetworkFailure(e.message);
    if (e is AuthException) return AuthFailure(e.message);
    if (e is ForbiddenException) return ForbiddenFailure(e.message);
    if (e is NotFoundException) return NotFoundFailure(e.message);
    if (e is ValidationException) {
      return ValidationFailure(e.message, errors: e.errors);
    }
    return ServerFailure(e.message);
  }
}
