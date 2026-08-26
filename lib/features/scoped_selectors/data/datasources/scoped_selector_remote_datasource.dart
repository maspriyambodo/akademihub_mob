import 'package:dio/dio.dart';

import '../models/scoped_selector_models.dart';

/// Server remains the authority for every selector scope and permission check.
abstract class ScopedSelectorRemoteDataSource {
  Future<List<GuruMapelOptionModel>> getGuruMapelSaya();
  Future<List<KelasSelectorModel>> getKelasAccessible({int? waliGuruId});
  Future<List<SiswaSelectorModel>> getSiswaByKelas(int kelasId);
  Future<List<UjianSelectorModel>> getUjianByKelas(int kelasId);
  Future<List<SemesterSelectorModel>> getSemester();
}

class ScopedSelectorRemoteDataSourceImpl
    implements ScopedSelectorRemoteDataSource {
  final Dio _dio;

  const ScopedSelectorRemoteDataSourceImpl(this._dio);

  @override
  Future<List<GuruMapelOptionModel>> getGuruMapelSaya() async => _rows(
    (await _dio.get('/guru-mapel/saya')).data,
  ).map(GuruMapelOptionModel.fromJson).toList();

  @override
  Future<List<KelasSelectorModel>> getKelasAccessible({
    int? waliGuruId,
  }) async => _rows(
    (await _dio.get(
      '/kelas',
      queryParameters: {'per_page': 'all', 'wali_guru_id': ?waliGuruId},
    )).data,
  ).map(KelasSelectorModel.fromJson).toList();

  @override
  Future<List<SiswaSelectorModel>> getSiswaByKelas(int kelasId) async {
    final body = (await _dio.get('/kelas/$kelasId/siswa')).data;
    final data = body is Map ? body['data'] : null;
    final siswa = data is Map ? data['siswa'] : null;
    return _rows(siswa).map(SiswaSelectorModel.fromJson).toList();
  }

  @override
  Future<List<UjianSelectorModel>> getUjianByKelas(int kelasId) async => _rows(
    (await _dio.get('/akademik/ujian/kelas/$kelasId')).data,
  ).map(UjianSelectorModel.fromJson).toList();

  @override
  Future<List<SemesterSelectorModel>> getSemester() async => _rows(
    (await _dio.get(
      '/admin/semester',
      queryParameters: const {'per_page': 'all'},
    )).data,
  ).map(SemesterSelectorModel.fromJson).toList();

  List<Map<String, dynamic>> _rows(dynamic body) {
    final raw = body is Map ? (body['rowData'] ?? body['data']) : body;
    final rows = raw is Map ? raw['data'] : raw;
    return rows is List
        ? rows.whereType<Map>().map(Map<String, dynamic>.from).toList()
        : const [];
  }
}
