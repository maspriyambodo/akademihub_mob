import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/error/exceptions.dart';
import '../models/rapor_detail_model.dart';
import '../models/rapor_model.dart';

abstract class RaporRemoteDataSource {
  Future<List<RaporModel>> getRaporList({String? search});
  Future<List<RaporModel>> getRaporBySiswa(int siswaId);
  Future<RaporDetailModel> getRaporDetail(int raporId);
  Future<RaporModel> createRapor({
    required int siswaId,
    required int semester,
    String? catatanWali,
    int? sakit,
    int? izin,
    int? tanpaKeterangan,
    List<Map<String, dynamic>>? details,
  });
  Future<RaporModel> updateRapor({
    required int id,
    int? siswaId,
    int? semester,
    String? catatanWali,
    int? sakit,
    int? izin,
    int? tanpaKeterangan,
  });
  Future<bool> deleteRapor(int id);

  /// Mengunduh xlsx rapor dan menyimpannya ke direktori sementara aplikasi.
  /// Mengembalikan path file lokal.
  Future<String> exportRaporSiswa(int siswaId);
}

class RaporRemoteDataSourceImpl implements RaporRemoteDataSource {
  final Dio _dio;

  const RaporRemoteDataSourceImpl(this._dio);

  /// Endpoint index memakai `AgGridControllerTrait`:
  /// - tanpa `startRow`/`endRow` → paginatedResponse: `{ "data": [...] }`
  ///   (kadang `{ "data": { "data": [...] } }`)
  /// - dengan `startRow`/`endRow` → agGridResponse: `{ "rowData": [...] }`
  ///
  /// Kita mengirim `startRow`/`endRow` supaya filter `search` benar-benar
  /// diterapkan (mode tradisional hanya mendukung filter siswa_id & semester),
  /// tapi tetap menangani kedua bentuk response.
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

  List<RaporModel> _parseList(dynamic body) {
    final list = _extractList(body);
    final result = <RaporModel>[];
    for (final item in list) {
      if (item is Map<String, dynamic>) {
        result.add(RaporModel.fromJson(item));
      }
    }
    return result;
  }

  RaporModel _parseRapor(dynamic body, String message) {
    final raw = body is Map ? body['data'] : null;
    if (raw is! Map) throw ServerException(message);
    return RaporModel.fromJson(Map<String, dynamic>.from(raw));
  }

  @override
  Future<List<RaporModel>> getRaporList({String? search}) async {
    final response = await _dio.get(
      '/akademik/rapor',
      queryParameters: <String, dynamic>{
        'startRow': 0,
        'endRow': 200,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      },
    );
    return _parseList(response.data);
  }

  @override
  Future<List<RaporModel>> getRaporBySiswa(int siswaId) async {
    final response = await _dio.get('/akademik/rapor/siswa/$siswaId');
    return _parseList(response.data);
  }

  @override
  Future<RaporDetailModel> getRaporDetail(int raporId) async {
    final response = await _dio.get('/akademik/rapor/$raporId/detail');
    final raw = response.data is Map ? response.data['data'] : null;

    // Backend mengembalikan `data: []` bila rapor tidak ada / tidak diizinkan.
    if (raw is! Map<String, dynamic> || raw.isEmpty) {
      throw const NotFoundException('Detail rapor tidak tersedia');
    }
    return RaporDetailModel.fromJson(raw);
  }

  @override
  Future<RaporModel> createRapor({
    required int siswaId,
    required int semester,
    String? catatanWali,
    int? sakit,
    int? izin,
    int? tanpaKeterangan,
    List<Map<String, dynamic>>? details,
  }) async {
    final response = await _dio.post(
      '/akademik/rapor',
      data: <String, dynamic>{
        'mst_siswa_id': siswaId,
        'semester': semester,
        'catatan_wali': ?catatanWali,
        'sakit': ?sakit,
        'izin': ?izin,
        'tanpa_keterangan': ?tanpaKeterangan,
        'details': ?details,
      },
    );
    return _parseRapor(response.data, 'Respons pembuatan rapor tidak valid');
  }

  @override
  Future<RaporModel> updateRapor({
    required int id,
    int? siswaId,
    int? semester,
    String? catatanWali,
    int? sakit,
    int? izin,
    int? tanpaKeterangan,
  }) async {
    final response = await _dio.put(
      '/akademik/rapor/$id',
      data: <String, dynamic>{
        'mst_siswa_id': ?siswaId,
        'semester': ?semester,
        'catatan_wali': ?catatanWali,
        'sakit': ?sakit,
        'izin': ?izin,
        'tanpa_keterangan': ?tanpaKeterangan,
      },
    );
    return _parseRapor(response.data, 'Respons perubahan rapor tidak valid');
  }

  @override
  Future<bool> deleteRapor(int id) async {
    await _dio.delete('/akademik/rapor/$id');
    return true;
  }

  @override
  Future<String> exportRaporSiswa(int siswaId) async {
    final response = await _dio.get<List<int>>(
      '/akademik/rapor/siswa/$siswaId/export',
      options: Options(
        responseType: ResponseType.bytes,
        headers: <String, dynamic>{'Accept': '*/*'},
      ),
    );

    final bytes = response.data;
    if (bytes == null || bytes.isEmpty) {
      throw const ServerException('Berkas rapor kosong');
    }

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/rapor_$siswaId.xlsx');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }
}
