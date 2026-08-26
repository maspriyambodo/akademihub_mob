import 'package:dio/dio.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../datasources/nilai_remote_datasource.dart';
import '../../domain/entities/nilai_entity.dart';
import '../../domain/repositories/nilai_repository.dart';

class NilaiRepositoryImpl implements NilaiRepository {
  final NilaiRemoteDataSource _remote;

  const NilaiRepositoryImpl(this._remote);

  @override
  Future<Result<List<NilaiEntity>>> getNilaiBySiswa(int siswaId) async {
    try {
      final models = await _remote.getNilaiBySiswa(siswaId);
      return success(models.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    }
  }

  @override
  Future<Result<List<NilaiEntity>>> getNilaiByUjian(int ujianId) async {
    try {
      final models = await _remote.getNilaiByUjian(ujianId);
      return success(models.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    }
  }

  @override
  Future<Result<List<NilaiEntity>>> getNilaiGeneral({
    int? siswaId,
    int? ujianId,
    int perPage = 100,
  }) async {
    try {
      final models = await _remote.getNilaiGeneral(
        siswaId: siswaId,
        ujianId: ujianId,
        perPage: perPage,
      );
      return success(models.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    }
  }

  @override
  Future<Result<double?>> getRataRataSiswa(int siswaId) async {
    try {
      final rataRata = await _remote.getRataRataSiswa(siswaId);
      return success(rataRata);
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    }
  }

  @override
  Future<Result<NilaiEntity>> createNilai({
    required int siswaId,
    required int ujianId,
    required double nilai,
    String? keterangan,
  }) async {
    try {
      final model = await _remote.createNilai(
        siswaId: siswaId,
        ujianId: ujianId,
        nilai: nilai,
        keterangan: keterangan,
      );
      return success(model.toEntity());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    }
  }

  @override
  Future<Result<NilaiEntity>> updateNilai({
    required int id,
    int? siswaId,
    int? ujianId,
    double? nilai,
    String? keterangan,
  }) async {
    try {
      final model = await _remote.updateNilai(
        id: id,
        siswaId: siswaId,
        ujianId: ujianId,
        nilai: nilai,
        keterangan: keterangan,
      );
      return success(model.toEntity());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    }
  }

  @override
  Future<Result<bool>> deleteNilai(int id) async {
    try {
      return success(await _remote.deleteNilai(id));
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    }
  }

  Failure _map(AppException e) {
    if (e is NetworkException) return NetworkFailure(e.message);
    if (e is AuthException) return AuthFailure(e.message);
    if (e is ForbiddenException) return ForbiddenFailure(e.message);
    return ServerFailure(e.message);
  }
}
