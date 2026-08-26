import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/app_info_entity.dart';
import '../../domain/entities/perangkat_entity.dart';
import '../../domain/entities/sekolah_entity.dart';
import '../../domain/repositories/profil_repository.dart';
import '../datasources/profil_local_datasource.dart';
import '../datasources/profil_remote_datasource.dart';
import '../models/sekolah_model.dart';

class ProfilRepositoryImpl implements ProfilRepository {
  final ProfilRemoteDataSource _remote;
  final ProfilLocalDataSource _local;

  const ProfilRepositoryImpl(this._remote, this._local);

  @override
  Future<Result<SekolahEntity>> getSekolahAktif({
    int? id,
    String? uuid,
    String? nama,
  }) async {
    try {
      if (id != null) {
        final model = await _remote.getSekolahById(id);
        return success(model.toEntity());
      }

      if (uuid != null && uuid.isNotEmpty) {
        final model = await _remote.getSekolahByUuid(uuid);
        return success(model.toEntity());
      }

      // Tanpa id/uuid: backend belum memaparkan `mst_sekolah_id` user di
      // `/auth/me`, jadi sekolah aktif dicari lewat daftar `/sekolah` lalu
      // dicocokkan dengan nama tenant yang tersimpan di perangkat.
      final list = await _remote.getSekolahList(search: nama);
      final match = _cariSekolah(list, nama);
      if (match == null) {
        return fail(const NotFoundFailure('Data sekolah tidak ditemukan'));
      }
      return success(match.toEntity());
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    }
  }

  SekolahModel? _cariSekolah(List<SekolahModel> list, String? nama) {
    if (list.isEmpty) return null;
    if (list.length == 1) return list.first;

    final target = nama?.trim().toLowerCase();
    if (target == null || target.isEmpty) return null;

    for (final item in list) {
      if (item.namaSekolah.trim().toLowerCase() == target) return item;
    }
    for (final item in list) {
      final n = item.namaSekolah.trim().toLowerCase();
      if (n.contains(target) || target.contains(n)) return item;
    }
    return null;
  }

  @override
  Future<Result<SekolahEntity?>> getSekolahTersimpan() async {
    final model = await _local.getSekolahTersimpan();
    return success(model?.toEntity());
  }

  @override
  Future<Result<List<PerangkatEntity>>> getPerangkatUser(int userId) async {
    try {
      final models = await _remote.getPerangkatUser(userId);
      final items = models.map((m) => m.toEntity()).toList()
        ..sort((a, b) {
          final ab = b.lastActiveAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final aa = a.lastActiveAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return ab.compareTo(aa); // paling baru di atas
        });
      return success(items);
    } on DioException catch (e) {
      return fail(_map(mapDioException(e)));
    }
  }

  @override
  Future<Result<AppInfoEntity>> getAppInfo() async {
    final model = await _local.getAppInfo();
    return success(model.toEntity());
  }

  Failure _map(AppException e) {
    if (e is NetworkException) return NetworkFailure(e.message);
    if (e is AuthException) return AuthFailure(e.message);
    if (e is ForbiddenException) return ForbiddenFailure(e.message);
    if (e is NotFoundException) return NotFoundFailure(e.message);
    return ServerFailure(e.message);
  }
}
