import 'package:dio/dio.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../datasources/tugas_remote_datasource.dart';
import '../../domain/entities/tugas_entity.dart';
import '../../domain/entities/tugas_siswa_entity.dart';
import '../../domain/repositories/tugas_repository.dart';

class TugasRepositoryImpl implements TugasRepository {
  final TugasRemoteDataSource _remote;

  const TugasRepositoryImpl(this._remote);

  @override
  Future<Result<List<TugasEntity>>> getTugasList({
    int? status,
    String? search,
  }) async {
    try {
      final models = await _remote.getTugasList(status: status, search: search);
      return success(models.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    }
  }

  @override
  Future<Result<TugasEntity>> getTugasDetail(int id) async {
    try {
      final model = await _remote.getTugasDetail(id);
      return success(model.toEntity());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    }
  }

  @override
  Future<Result<List<TugasEntity>>> getTugasByKelas(int kelasId) async {
    try {
      final models = await _remote.getTugasByKelas(kelasId);
      return success(models.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    }
  }

  @override
  Future<Result<List<TugasEntity>>> getTugasByGuruMapel(
    int guruMapelId,
  ) async {
    try {
      final models = await _remote.getTugasByGuruMapel(guruMapelId);
      return success(models.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    }
  }

  @override
  Future<Result<List<TugasSiswaEntity>>> getPengumpulanList() async {
    try {
      final models = await _remote.getPengumpulanList();
      return success(models.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    }
  }

  @override
  Future<Result<List<TugasSiswaEntity>>> getPengumpulanByTugas(
    int tugasId,
  ) async {
    try {
      final models = await _remote.getPengumpulanByTugas(tugasId);
      return success(models.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    }
  }

  @override
  Future<Result<List<TugasSiswaEntity>>> getPengumpulanBySiswa(
    int siswaId,
  ) async {
    try {
      final models = await _remote.getPengumpulanBySiswa(siswaId);
      return success(models.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    }
  }

  @override
  Future<Result<TugasSiswaEntity>> kumpulkanTugas({
    required int siswaId,
    required int tugasId,
    String? jawaban,
    String? fileJawaban,
  }) async {
    try {
      final model = await _remote.kumpulkan(
        siswaId: siswaId,
        tugasId: tugasId,
        jawaban: jawaban,
        fileJawaban: fileJawaban,
      );
      return success(model.toEntity());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    }
  }

  @override
  Future<Result<TugasSiswaEntity>> nilaiTugas({
    required int pengumpulanId,
    required double nilai,
    String? catatanGuru,
  }) async {
    try {
      final model = await _remote.nilai(
        pengumpulanId: pengumpulanId,
        nilai: nilai,
        catatanGuru: catatanGuru,
      );
      return success(model.toEntity());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    }
  }

  Failure _map(AppException e) {
    if (e is NetworkException) return NetworkFailure(e.message);
    if (e is AuthException) return AuthFailure(e.message);
    if (e is ValidationException) {
      return ValidationFailure(e.message, errors: e.errors);
    }
    if (e is NotFoundException) return NotFoundFailure(e.message);
    return ServerFailure(e.message);
  }
}
