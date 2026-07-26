import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../models/ppdb_dokumen_model.dart';
import '../models/ppdb_gelombang_model.dart';
import '../models/ppdb_hasil_seleksi_model.dart';
import '../models/ppdb_nilai_rapor_model.dart';
import '../models/ppdb_pendaftar_model.dart';
import '../models/ppdb_statistik_model.dart';

class PpdbNilaiRaporResponse {
  final List<PpdbNilaiRaporModel> daftar;
  final PpdbNilaiStatistikModel statistik;

  const PpdbNilaiRaporResponse({
    this.daftar = const [],
    this.statistik = const PpdbNilaiStatistikModel(),
  });
}

abstract class PpdbRemoteDataSource {
  Future<List<PpdbGelombangModel>> getGelombangList();
  Future<List<PpdbPendaftarModel>> getPendaftarList({
    String? search,
    String? statusPendaftaran,
    int? gelombangId,
  });
  Future<PpdbPendaftarModel> getPendaftarDetail(int id);
  Future<PpdbStatistikModel> getStatistik({
    required int sekolahId,
    int? gelombangId,
  });
  Future<List<PpdbDokumenModel>> getDokumenByPendaftar(int pendaftarId);
  Future<PpdbNilaiRaporResponse> getNilaiRapor(int pendaftarId);
  Future<List<PpdbHasilSeleksiModel>> getHasilSeleksi(int gelombangId);
  Future<PpdbDokumenModel> verifikasiDokumen(int dokumenId, {String? catatan});
  Future<PpdbDokumenModel> tolakDokumen(
    int dokumenId, {
    required String catatan,
  });
  Future<PpdbPendaftarModel> ubahStatusPendaftar(
    int pendaftarId, {
    required String aksi,
  });
}

class PpdbRemoteDataSourceImpl implements PpdbRemoteDataSource {
  final Dio _dio;

  const PpdbRemoteDataSourceImpl(this._dio);

  /// Endpoint index PPDB memakai `AgGridControllerTrait`:
  /// - tanpa `startRow`/`endRow` → paginatedResponse: `{ "data": [...] }`
  ///   (kadang `{ "data": { "data": [...] } }`)
  /// - dengan `startRow`/`endRow` → agGridResponse: `{ "rowData": [...] }`
  /// Parser ini menangani ketiganya.
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

  Map<String, dynamic> _extractMap(dynamic body) {
    final raw = body is Map ? body['data'] : null;
    if (raw is Map<String, dynamic>) return raw;
    throw const ServerException('Format response tidak dikenali');
  }

  @override
  Future<List<PpdbGelombangModel>> getGelombangList() async {
    // Jalur tradisional (tanpa startRow/endRow) dipakai supaya filter
    // query biasa tetap jalan; per_page=all agar semua gelombang termuat.
    final response = await _dio.get(
      '/ppdb/gelombang',
      queryParameters: <String, dynamic>{'per_page': 'all'},
    );
    return _extractList(response.data)
        .whereType<Map<String, dynamic>>()
        .map(PpdbGelombangModel.fromJson)
        .toList();
  }

  @override
  Future<List<PpdbPendaftarModel>> getPendaftarList({
    String? search,
    String? statusPendaftaran,
    int? gelombangId,
  }) async {
    // PENTING: jalur tradisional (tanpa startRow/endRow) dipakai karena
    // HANYA jalur ini yang menerapkan `search` ke nama, no_pendaftaran,
    // email, dan nisn sekaligus filter status & gelombang
    // (`PpdbPendaftaranService::getAllPendaftaran`). Jalur AG-Grid hanya
    // mencari di nama_lengkap dan mengabaikan filter status/gelombang.
    final response = await _dio.get(
      '/ppdb/pendaftaran',
      queryParameters: <String, dynamic>{
        'per_page': 200,
        if (search != null && search.trim().isNotEmpty)
          'search': search.trim(),
        if (statusPendaftaran != null && statusPendaftaran.isNotEmpty)
          'status_pendaftaran': statusPendaftaran,
        'ppdb_gelombang_id': ?gelombangId,
      },
    );
    return _extractList(response.data)
        .whereType<Map<String, dynamic>>()
        .map(PpdbPendaftarModel.fromJson)
        .toList();
  }

  @override
  Future<PpdbPendaftarModel> getPendaftarDetail(int id) async {
    final response = await _dio.get('/ppdb/pendaftaran/$id');
    return PpdbPendaftarModel.fromJson(_extractMap(response.data));
  }

  @override
  Future<PpdbStatistikModel> getStatistik({
    required int sekolahId,
    int? gelombangId,
  }) async {
    final response = await _dio.get(
      '/ppdb/pendaftaran/sekolah/$sekolahId/statistics',
      queryParameters: <String, dynamic>{'ppdb_gelombang_id': ?gelombangId},
    );
    return PpdbStatistikModel.fromJson(_extractMap(response.data));
  }

  @override
  Future<List<PpdbDokumenModel>> getDokumenByPendaftar(int pendaftarId) async {
    final response = await _dio.get('/ppdb/dokumen/pendaftaran/$pendaftarId');
    return _extractList(response.data)
        .whereType<Map<String, dynamic>>()
        .map(PpdbDokumenModel.fromJson)
        .toList();
  }

  @override
  Future<PpdbNilaiRaporResponse> getNilaiRapor(int pendaftarId) async {
    final response = await _dio.get('/ppdb/nilai-rapor/pendaftaran/$pendaftarId');
    final data = _extractMap(response.data);

    final daftarRaw = data['nilai_rapor'];
    final daftar = daftarRaw is List
        ? daftarRaw
              .whereType<Map<String, dynamic>>()
              .map(PpdbNilaiRaporModel.fromJson)
              .toList()
        : <PpdbNilaiRaporModel>[];

    final statistikRaw = data['statistik'];
    final statistik = statistikRaw is Map<String, dynamic>
        ? PpdbNilaiStatistikModel.fromJson(statistikRaw)
        : const PpdbNilaiStatistikModel();

    return PpdbNilaiRaporResponse(daftar: daftar, statistik: statistik);
  }

  @override
  Future<List<PpdbHasilSeleksiModel>> getHasilSeleksi(int gelombangId) async {
    final response = await _dio.get('/ppdb/seleksi/gelombang/$gelombangId/hasil');
    return _extractList(response.data)
        .whereType<Map<String, dynamic>>()
        .map(PpdbHasilSeleksiModel.fromJson)
        .toList();
  }

  @override
  Future<PpdbDokumenModel> verifikasiDokumen(
    int dokumenId, {
    String? catatan,
  }) async {
    final response = await _dio.post(
      '/ppdb/dokumen/$dokumenId/verify',
      data: <String, dynamic>{
        if (catatan != null && catatan.trim().isNotEmpty)
          'catatan': catatan.trim(),
      },
    );
    return PpdbDokumenModel.fromJson(_extractMap(response.data));
  }

  @override
  Future<PpdbDokumenModel> tolakDokumen(
    int dokumenId, {
    required String catatan,
  }) async {
    final response = await _dio.post(
      '/ppdb/dokumen/$dokumenId/reject',
      data: <String, dynamic>{'catatan': catatan},
    );
    return PpdbDokumenModel.fromJson(_extractMap(response.data));
  }

  @override
  Future<PpdbPendaftarModel> ubahStatusPendaftar(
    int pendaftarId, {
    required String aksi,
  }) async {
    // aksi: verify | accept | reject (POST tanpa body).
    final response = await _dio.post('/ppdb/pendaftaran/$pendaftarId/$aksi');
    return PpdbPendaftarModel.fromJson(_extractMap(response.data));
  }
}
