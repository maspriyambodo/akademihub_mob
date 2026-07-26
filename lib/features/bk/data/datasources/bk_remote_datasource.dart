import 'package:dio/dio.dart';

import '../models/bk_hasil_model.dart';
import '../models/bk_jenis_model.dart';
import '../models/bk_kasus_model.dart';
import '../models/bk_sesi_model.dart';
import '../models/bk_siswa_ringkas_model.dart';
import '../models/bk_tindakan_model.dart';

abstract class BkRemoteDataSource {
  Future<List<BkKasusModel>> getKasusList();
  Future<List<BkKasusModel>> getKasusBySiswa(int siswaId);
  Future<List<BkSesiModel>> getSesiByKasus(int kasusId);
  Future<List<BkHasilModel>> getHasilByKasus(int kasusId);
  Future<List<BkTindakanModel>> getTindakanByKasus(int kasusId);
  Future<List<BkJenisModel>> getJenisList();
  Future<List<BkSiswaRingkasModel>> searchSiswa(String query);

  Future<BkKasusModel> createKasus({
    required int siswaId,
    required int guruId,
    required int jenisId,
    required String tanggal,
    required String keterangan,
  });

  Future<BkSesiModel> createSesi({
    required int kasusId,
    required String tanggal,
    required int metode,
    required String catatan,
  });

  Future<BkHasilModel> createHasil({
    required int kasusId,
    required String hasil,
    required String rekomendasi,
  });

  Future<BkTindakanModel> createTindakan({
    required int kasusId,
    required String deskripsi,
  });
}

class BkRemoteDataSourceImpl implements BkRemoteDataSource {
  final Dio _dio;

  const BkRemoteDataSourceImpl(this._dio);

  /// Endpoint index BK memakai `AgGridControllerTrait`, jadi envelope bisa:
  /// - `{ "rowData": [...] }` (dikirim `startRow`/`endRow`),
  /// - `{ "data": [...] }`, atau
  /// - `{ "data": { "data": [...] } }` (paginatedResponse).
  List<dynamic> _extractList(dynamic body) {
    if (body is! Map) return const [];

    final rowData = body['rowData'];
    if (rowData is List) return rowData;

    final raw = body['data'];
    if (raw is List) return raw;
    if (raw is Map) {
      final nested = raw['data'];
      if (nested is List) return nested;
    }
    return const [];
  }

  List<T> _mapList<T>(
    dynamic body,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final result = <T>[];
    for (final item in _extractList(body)) {
      if (item is Map<String, dynamic>) {
        result.add(fromJson(item));
      }
    }
    return result;
  }

  @override
  Future<List<BkKasusModel>> getKasusList() async {
    // Mode AG-Grid (startRow/endRow) dipakai agar relasi siswa/guru/jenis
    // ikut dimuat dan bentuk response deterministik (`rowData`).
    final response = await _dio.get(
      '/bk/kasus',
      queryParameters: <String, dynamic>{'startRow': 0, 'endRow': 200},
    );
    return _mapList(response.data, BkKasusModel.fromJson);
  }

  @override
  Future<List<BkKasusModel>> getKasusBySiswa(int siswaId) async {
    final response = await _dio.get('/bk/kasus/siswa/$siswaId');
    return _mapList(response.data, BkKasusModel.fromJson);
  }

  @override
  Future<List<BkSesiModel>> getSesiByKasus(int kasusId) async {
    final response = await _dio.get(
      '/bk/sesi',
      queryParameters: <String, dynamic>{
        'trx_bk_kasus_id': kasusId,
        'startRow': 0,
        'endRow': 200,
      },
    );
    return _mapList(response.data, BkSesiModel.fromJson);
  }

  @override
  Future<List<BkHasilModel>> getHasilByKasus(int kasusId) async {
    final response = await _dio.get(
      '/bk/hasil',
      queryParameters: <String, dynamic>{
        'trx_bk_kasus_id': kasusId,
        'startRow': 0,
        'endRow': 200,
      },
    );
    return _mapList(response.data, BkHasilModel.fromJson);
  }

  @override
  Future<List<BkTindakanModel>> getTindakanByKasus(int kasusId) async {
    final response = await _dio.get(
      '/bk/tindakan',
      queryParameters: <String, dynamic>{
        'trx_bk_kasus_id': kasusId,
        'startRow': 0,
        'endRow': 200,
      },
    );
    return _mapList(response.data, BkTindakanModel.fromJson);
  }

  @override
  Future<List<BkJenisModel>> getJenisList() async {
    final response = await _dio.get(
      '/bk/jenis',
      queryParameters: <String, dynamic>{'startRow': 0, 'endRow': 100},
    );
    return _mapList(response.data, BkJenisModel.fromJson);
  }

  @override
  Future<List<BkSiswaRingkasModel>> searchSiswa(String query) async {
    // Mode tradisional dipakai karena filter `search` (nama/NIS) diverifikasi
    // ada di `SiswaRepository::paginateWithFilters`.
    final response = await _dio.get(
      '/siswa',
      queryParameters: <String, dynamic>{
        if (query.trim().isNotEmpty) 'search': query.trim(),
        'per_page': 20,
      },
    );
    return _mapList(response.data, BkSiswaRingkasModel.fromJson);
  }

  @override
  Future<BkKasusModel> createKasus({
    required int siswaId,
    required int guruId,
    required int jenisId,
    required String tanggal,
    required String keterangan,
  }) async {
    // Field diverifikasi dari `CreateBkKasusRequest`:
    // siswa_id, guru_id, jenis_id, tanggal, keterangan wajib; status opsional
    // (default 1 = dibuka di service).
    final response = await _dio.post(
      '/bk/kasus',
      data: <String, dynamic>{
        'siswa_id': siswaId,
        'guru_id': guruId,
        'jenis_id': jenisId,
        'tanggal': tanggal,
        'keterangan': keterangan,
      },
    );
    final raw = response.data is Map ? response.data['data'] : null;
    return BkKasusModel.fromJson(
      raw is Map<String, dynamic> ? raw : <String, dynamic>{},
    );
  }

  @override
  Future<BkSesiModel> createSesi({
    required int kasusId,
    required String tanggal,
    required int metode,
    required String catatan,
  }) async {
    // Field diverifikasi dari `CreateBkSesiRequest`.
    final response = await _dio.post(
      '/bk/sesi',
      data: <String, dynamic>{
        'trx_bk_kasus_id': kasusId,
        'tanggal': tanggal,
        'metode': metode,
        'catatan': catatan,
      },
    );
    final raw = response.data is Map ? response.data['data'] : null;
    return BkSesiModel.fromJson(
      raw is Map<String, dynamic> ? raw : <String, dynamic>{},
    );
  }

  @override
  Future<BkHasilModel> createHasil({
    required int kasusId,
    required String hasil,
    required String rekomendasi,
  }) async {
    // Field diverifikasi dari `CreateBkHasilRequest`.
    final response = await _dio.post(
      '/bk/hasil',
      data: <String, dynamic>{
        'trx_bk_kasus_id': kasusId,
        'hasil': hasil,
        'rekomendasi': rekomendasi,
      },
    );
    final raw = response.data is Map ? response.data['data'] : null;
    return BkHasilModel.fromJson(
      raw is Map<String, dynamic> ? raw : <String, dynamic>{},
    );
  }

  @override
  Future<BkTindakanModel> createTindakan({
    required int kasusId,
    required String deskripsi,
  }) async {
    // Field diverifikasi dari `CreateBkTindakanRequest`.
    final response = await _dio.post(
      '/bk/tindakan',
      data: <String, dynamic>{
        'trx_bk_kasus_id': kasusId,
        'deskripsi_tindakan': deskripsi,
      },
    );
    final raw = response.data is Map ? response.data['data'] : null;
    return BkTindakanModel.fromJson(
      raw is Map<String, dynamic> ? raw : <String, dynamic>{},
    );
  }
}
