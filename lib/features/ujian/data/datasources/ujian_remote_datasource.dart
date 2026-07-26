import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/error/exceptions.dart';
import '../models/kelas_option_model.dart';
import '../models/ranking_model.dart';
import '../models/ujian_model.dart';
import '../models/ujian_nilai_model.dart';

abstract class UjianRemoteDataSource {
  Future<List<UjianModel>> getUjianByKelas(int kelasId);
  Future<UjianNilaiDetailModel> getNilaiUjian(int ujianId);
  Future<List<RankingModel>> getRankingByKelas(int kelasId);
  Future<List<RankingModel>> generateRanking({
    required int kelasId,
    required int semesterId,
    required int tahunAjaranId,
  });

  /// Mengunduh xlsx ranking dan menyimpannya ke direktori sementara.
  /// Mengembalikan path file lokal.
  Future<String> exportRanking({
    required int kelasId,
    required int semesterId,
    required int tahunAjaranId,
  });

  Future<List<KelasOptionModel>> getKelasOptions({int? waliGuruId});
}

class UjianRemoteDataSourceImpl implements UjianRemoteDataSource {
  final Dio _dio;

  const UjianRemoteDataSourceImpl(this._dio);

  /// Envelope backend bisa berupa `{"rowData": [...]}` (jalur AG-Grid),
  /// `{"data": [...]}` (Resource collection), atau `{"data": {"data": [...]}}`
  /// (paginator). Tangani ketiganya.
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

  @override
  Future<List<UjianModel>> getUjianByKelas(int kelasId) async {
    final response = await _dio.get('/akademik/ujian/kelas/$kelasId');
    return _extractList(response.data)
        .whereType<Map<String, dynamic>>()
        .map(UjianModel.fromJson)
        .toList();
  }

  @override
  Future<UjianNilaiDetailModel> getNilaiUjian(int ujianId) async {
    final response = await _dio.get('/akademik/ujian/$ujianId/nilai');
    final raw = response.data is Map ? response.data['data'] : null;

    // `UjianService::getNilaiByUjian` mengembalikan `[]` (List kosong)
    // bila ujian tidak ditemukan — bukan Map.
    if (raw is! Map<String, dynamic> || raw.isEmpty) {
      throw const NotFoundException('Data ujian tidak ditemukan');
    }
    return UjianNilaiDetailModel.fromJson(raw);
  }

  @override
  Future<List<RankingModel>> getRankingByKelas(int kelasId) async {
    final response = await _dio.get('/akademik/ranking/kelas/$kelasId');
    return _extractList(response.data)
        .whereType<Map<String, dynamic>>()
        .map(RankingModel.fromJson)
        .toList();
  }

  @override
  Future<List<RankingModel>> generateRanking({
    required int kelasId,
    required int semesterId,
    required int tahunAjaranId,
  }) async {
    final response = await _dio.post(
      '/akademik/ranking/generate',
      data: <String, dynamic>{
        'kelas_id': kelasId,
        'semester': semesterId,
        'tahun_ajaran': tahunAjaranId,
      },
    );
    return _extractList(response.data)
        .whereType<Map<String, dynamic>>()
        .map(RankingModel.fromJson)
        .toList();
  }

  @override
  Future<String> exportRanking({
    required int kelasId,
    required int semesterId,
    required int tahunAjaranId,
  }) async {
    final response = await _dio.get<List<int>>(
      '/akademik/ranking/kelas/$kelasId/export',
      queryParameters: <String, dynamic>{
        'semester': semesterId,
        'tahun_ajaran': tahunAjaranId,
      },
      options: Options(
        responseType: ResponseType.bytes,
        headers: <String, dynamic>{'Accept': '*/*'},
      ),
    );

    final bytes = response.data;
    if (bytes == null || bytes.isEmpty) {
      throw const ServerException('Berkas ranking kosong');
    }

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/ranking_kelas_$kelasId.xlsx');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  @override
  Future<List<KelasOptionModel>> getKelasOptions({int? waliGuruId}) async {
    final response = await _dio.get(
      '/kelas',
      queryParameters: <String, dynamic>{
        // `KelasService::resolvePerPage` mendukung 'all' → semua kelas
        // (jumlah kelas per sekolah kecil, aman tanpa paging).
        'per_page': 'all',
        'wali_guru_id': ?waliGuruId,
      },
    );
    return _extractList(response.data)
        .whereType<Map<String, dynamic>>()
        .map(KelasOptionModel.fromJson)
        .toList();
  }
}
