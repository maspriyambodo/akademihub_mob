import 'dart:io';

import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../../../core/storage/answer_outbox.dart';
import '../../domain/entities/kelas_option_entity.dart';
import '../../domain/entities/ranking_entity.dart';
import '../../domain/entities/ujian_entity.dart';
import '../../domain/entities/ujian_nilai_entity.dart';
import '../../domain/entities/ujian_question_entity.dart';
import '../../domain/entities/ujian_session_entity.dart';
import '../../domain/repositories/ujian_repository.dart';
import '../datasources/ujian_remote_datasource.dart';

class UjianRepositoryImpl implements UjianRepository {
  final UjianRemoteDataSource _remote;
  final AnswerOutbox _outbox;

  const UjianRepositoryImpl(this._remote, this._outbox);

  @override
  Future<Result<List<UjianSessionEntity>>> getSesiUjian({int? siswaId}) async {
    try {
      final models = await _remote.getSesiUjian(siswaId: siswaId);
      return success(models.map((model) => model.toEntity()).toList());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    } on AppException catch (e) {
      return fail(_map(e));
    }
  }

  @override
  Future<Result<UjianSessionEntity>> getSesi(int sesiId) async {
    try {
      return success((await _remote.getSesi(sesiId)).toEntity());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    } on AppException catch (e) {
      return fail(_map(e));
    }
  }

  @override
  Future<Result<List<UjianQuestionEntity>>> getSoal(int sesiId) async {
    try {
      await _flush(sesiId);
      final questions = (await _remote.getSoal(
        sesiId,
      )).map((model) => model.toEntity()).toList();
      final pending = {
        for (final operation in _outbox.pending('cbt', sesiId))
          operation.questionId: operation,
      };
      return success([
        for (final question in questions)
          if (pending[question.id] case final operation?)
            question.copyWith(answer: _localAnswer(operation.payload))
          else
            question,
      ]);
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    } on AppException catch (e) {
      return fail(_map(e));
    }
  }

  @override
  Future<Result<UjianAnswerEntity>> saveJawaban({
    required int sesiId,
    required int soalId,
    int? opsiId,
    String? teks,
    required bool raguRagu,
  }) async {
    final payload = <String, dynamic>{
      'trx_ujian_user_id': sesiId,
      'mst_soal_id': soalId,
      'mst_soal_opsi_id': opsiId,
      'jawaban_teks': teks,
      'ragu_ragu': raguRagu,
    };
    final operation = await _outbox.enqueue(
      module: 'cbt',
      sessionId: sesiId,
      questionId: soalId,
      payload: payload,
    );
    try {
      final json = await _remote.saveJawaban(
        sesiId: sesiId,
        soalId: soalId,
        opsiId: opsiId,
        teks: teks,
        raguRagu: raguRagu,
      );
      await _outbox.acknowledge(operation);
      return success(
        UjianAnswerEntity(
          id: (json['id'] as num?)?.toInt() ?? 0,
          optionId: (json['mst_soal_opsi_id'] as num?)?.toInt(),
          text: json['jawaban_teks']?.toString(),
          doubtful:
              json['ragu_ragu'] == true ||
              (json['ragu_ragu'] as num?)?.toInt() == 1,
        ),
      );
    } on DioException catch (e) {
      final failure = _map(mapDioException(e));
      if (failure is NetworkFailure || failure is AuthFailure) {
        return success(_localAnswer(payload));
      }
      return fail(failure);
    } on AppException catch (e) {
      return fail(_map(e));
    }
  }

  @override
  Future<Result<int>> getJumlahJawaban(int sesiId) async {
    try {
      return success(await _remote.getJumlahJawaban(sesiId));
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    } on AppException catch (e) {
      return fail(_map(e));
    }
  }

  @override
  Future<Result<UjianSessionEntity>> mulaiSesi(int sesiId) async {
    try {
      return success((await _remote.mulaiSesi(sesiId)).toEntity());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    } on AppException catch (e) {
      return fail(_map(e));
    }
  }

  @override
  Future<Result<UjianSessionEntity>> selesaikanSesi(int sesiId) async {
    try {
      await _flush(sesiId);
      if (_outbox.pending('cbt', sesiId).isNotEmpty) {
        return fail(
          const NetworkFailure(
            'Jawaban belum tersinkron. Hubungkan internet lalu coba lagi.',
          ),
        );
      }
      final result = (await _remote.selesaikanSesi(sesiId)).toEntity();
      await _outbox.clearSession('cbt', sesiId);
      return success(result);
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    } on AppException catch (e) {
      return fail(_map(e));
    }
  }

  UjianAnswerEntity _localAnswer(Map<String, dynamic> payload) =>
      UjianAnswerEntity(
        id: 0,
        optionId: (payload['mst_soal_opsi_id'] as num?)?.toInt(),
        text: payload['jawaban_teks']?.toString(),
        doubtful: payload['ragu_ragu'] == true,
      );

  Future<void> _flush(int sesiId) async {
    for (final operation in _outbox.pending('cbt', sesiId)) {
      try {
        // ponytail: backoff caps at ~8s; upgrade to isolate worker if needed
        if (operation.retryCount > 0) {
          final delay = Duration(
            milliseconds: 500 * (1 << operation.retryCount.clamp(0, 4)),
          );
          await Future<void>.delayed(delay);
        }
        final payload = operation.payload;
        await _remote.saveJawaban(
          sesiId: sesiId,
          soalId: operation.questionId,
          opsiId: (payload['mst_soal_opsi_id'] as num?)?.toInt(),
          teks: payload['jawaban_teks']?.toString(),
          raguRagu: payload['ragu_ragu'] == true,
        );
        await _outbox.acknowledge(operation);
      } on DioException catch (e) {
        final code = e.response?.statusCode ?? 0;
        if (code >= 400 &&
            code < 500 &&
            code != 401 &&
            code != 408 &&
            code != 429) {
          // Non-retryable client error — drop to prevent infinite loop.
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
  Future<Result<Map<String, dynamic>>> reportViolation({
    required int sesiId,
    required String type,
  }) async {
    try {
      final res = await _remote.reportViolation(sesiId: sesiId, type: type);
      return success(res);
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    } on AppException catch (e) {
      return fail(_map(e));
    }
  }

  @override
  Future<Result<List<UjianEntity>>> getUjianByKelas(int kelasId) async {
    try {
      final models = await _remote.getUjianByKelas(kelasId);
      return success(models.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    } on AppException catch (e) {
      return fail(_map(e));
    }
  }

  @override
  Future<Result<UjianNilaiDetailEntity>> getNilaiUjian(int ujianId) async {
    try {
      final model = await _remote.getNilaiUjian(ujianId);
      return success(model.toEntity());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    } on AppException catch (e) {
      return fail(_map(e));
    }
  }

  @override
  Future<Result<List<RankingEntity>>> getRankingByKelas(int kelasId) async {
    try {
      final models = await _remote.getRankingByKelas(kelasId);
      return success(models.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    } on AppException catch (e) {
      return fail(_map(e));
    }
  }

  @override
  Future<Result<List<RankingEntity>>> generateRanking({
    required int kelasId,
    required int semesterId,
    required int tahunAjaranId,
  }) async {
    try {
      final models = await _remote.generateRanking(
        kelasId: kelasId,
        semesterId: semesterId,
        tahunAjaranId: tahunAjaranId,
      );
      return success(models.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    } on AppException catch (e) {
      return fail(_map(e));
    }
  }

  @override
  Future<Result<String>> exportRanking({
    required int kelasId,
    required int semesterId,
    required int tahunAjaranId,
  }) async {
    try {
      final path = await _remote.exportRanking(
        kelasId: kelasId,
        semesterId: semesterId,
        tahunAjaranId: tahunAjaranId,
      );
      return success(path);
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    } on AppException catch (e) {
      return fail(_map(e));
    } on FileSystemException catch (e) {
      return fail(
        ServerFailure('Gagal menyimpan berkas ranking: ${e.message}'),
      );
    }
  }

  @override
  Future<Result<List<KelasOptionEntity>>> getKelasOptions({
    int? waliGuruId,
  }) async {
    try {
      final models = await _remote.getKelasOptions(waliGuruId: waliGuruId);
      return success(models.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    } on AppException catch (e) {
      return fail(_map(e));
    }
  }

  Failure _map(AppException e) {
    if (e is NetworkException) return NetworkFailure(e.message);
    if (e is AuthException) return AuthFailure(e.message);
    if (e is ForbiddenException) return ForbiddenFailure(e.message);
    return ServerFailure(e.message);
  }
}
