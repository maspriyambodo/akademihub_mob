import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/kalender_event_entity.dart';
import '../../domain/entities/kalender_harian_entity.dart';
import '../../domain/entities/kalender_konteks_entity.dart';
import '../../domain/entities/kalender_tipe_entity.dart';
import '../../domain/repositories/kalender_repository.dart';
import '../datasources/kalender_remote_datasource.dart';

class KalenderRepositoryImpl implements KalenderRepository {
  final KalenderRemoteDataSource _remote;

  const KalenderRepositoryImpl(this._remote);

  @override
  Future<Result<List<KalenderEventEntity>>> getEvents({int limit = 500}) async {
    try {
      final models = await _remote.getEvents(limit: limit);
      final items = models
          .map((m) => m.toEntity())
          .where((e) => e.tanggalMulai.isNotEmpty)
          .toList();
      return success(items);
    } on DioException catch (e) {
      return fail(_map(e));
    }
  }

  @override
  Future<Result<List<KalenderHarianEntity>>> getHarian({
    int limit = 500,
  }) async {
    try {
      final models = await _remote.getHarian(limit: limit);
      final items = models
          .map((m) => m.toEntity())
          .where((e) => e.tanggal.isNotEmpty)
          .toList();
      return success(items);
    } on DioException catch (e) {
      return fail(_map(e));
    }
  }

  @override
  Future<Result<List<KalenderTipeEntity>>> getTipeList() async {
    try {
      final models = await _remote.getTipeList();
      return success(models.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      return fail(_map(e));
    }
  }

  /// Setiap bagian konteks diambil terpisah dan kegagalannya ditelan, karena
  /// `tahun-ajaran.view`, `semester.view`, dan `hari-operasional.view` adalah
  /// permission yang berbeda dari `kalender-akademik.view` — user bisa saja
  /// hanya punya sebagian. Header cukup menampilkan apa yang tersedia.
  @override
  Future<Result<KalenderKonteksEntity>> getKonteks() async {
    TahunAjaranEntity? tahunAjaran;
    SemesterEntity? semester;
    var hariOperasional = const <HariOperasionalEntity>[];

    try {
      tahunAjaran = (await _remote.getTahunAjaranAktif())?.toEntity();
    } on DioException catch (_) {
      tahunAjaran = null;
    }

    try {
      final list = (await _remote.getSemesterList())
          .map((m) => m.toEntity())
          .toList();
      for (final s in list) {
        if (s.isActive) {
          semester = s;
          break;
        }
      }
      // Bila tidak ada yang ditandai aktif, pakai semester milik tahun ajaran
      // aktif yang rentang tanggalnya memuat hari ini.
      if (semester == null && list.isNotEmpty) {
        final hariIni = DateTime.now();
        for (final s in list) {
          final mulai = s.tanggalMulai == null
              ? null
              : DateTime.tryParse(s.tanggalMulai!);
          final selesai = s.tanggalSelesai == null
              ? null
              : DateTime.tryParse(s.tanggalSelesai!);
          if (mulai != null &&
              selesai != null &&
              !hariIni.isBefore(mulai) &&
              !hariIni.isAfter(selesai.add(const Duration(days: 1)))) {
            semester = s;
            break;
          }
        }
      }
    } on DioException catch (_) {
      semester = null;
    }

    try {
      hariOperasional = (await _remote.getHariOperasional())
          .map((m) => m.toEntity())
          .toList();
    } on DioException catch (_) {
      hariOperasional = const [];
    }

    return success(
      KalenderKonteksEntity(
        tahunAjaranAktif: tahunAjaran,
        semesterAktif: semester,
        hariOperasional: hariOperasional,
      ),
    );
  }

  Failure _map(DioException e) {
    // 403 tidak punya padanan di `mapDioException` (jatuh ke ServerException),
    // padahal inilah kasus paling umum untuk modul ini: endpoint berada di
    // grup `admin` dan dilindungi PermissionMiddleware.
    if (e.response?.statusCode == 403) {
      final data = e.response?.data;
      final pesan = data is Map ? data['message']?.toString() : null;
      return KalenderAccessFailure(
        pesan == null || pesan.trim().isEmpty
            ? 'Anda tidak memiliki izin untuk melihat kalender akademik.'
            : pesan,
      );
    }
    return _mapException(mapDioException(e));
  }

  Failure _mapException(AppException e) {
    if (e is NetworkException) return NetworkFailure(e.message);
    if (e is AuthException) return AuthFailure(e.message);
    if (e is NotFoundException) return NotFoundFailure(e.message);
    return ServerFailure(e.message);
  }
}
