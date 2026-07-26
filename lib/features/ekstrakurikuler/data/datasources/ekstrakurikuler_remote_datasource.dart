import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../models/ekstrakurikuler_model.dart';
import '../models/ekstrakurikuler_statistik_model.dart';
import '../models/pendaftaran_ekskul_model.dart';

abstract class EkstrakurikulerRemoteDataSource {
  Future<List<EkstrakurikulerModel>> getEkstrakurikulerAktif();
  Future<List<EkstrakurikulerModel>> getEkstrakurikulerList({
    String? status,
    String? search,
  });
  Future<EkstrakurikulerModel> getEkstrakurikulerDetail(int id);
  Future<EkstrakurikulerStatistikModel> getStatistik(int id);
  Future<List<EkstrakurikulerModel>> getByPembina(int pembinaGuruId);

  Future<List<PendaftaranEkskulModel>> getPesertaByEkstrakurikuler(
    int ekstrakurikulerId,
  );
  Future<List<PendaftaranEkskulModel>> getPendaftaranBySiswa(int siswaId);
  Future<List<PendaftaranEkskulModel>> getRiwayatBySiswa(int siswaId);
  Future<List<PendaftaranEkskulModel>> getPendaftaranList({
    int? siswaId,
    int? ekstrakurikulerId,
    String? status,
  });

  Future<PendaftaranEkskulModel> daftar({
    required int ekstrakurikulerId,
    required int siswaId,
  });
  Future<bool> checkStatus({
    required int siswaId,
    required int ekstrakurikulerId,
  });
  Future<PendaftaranEkskulModel> keluar(int pendaftaranId);
}

/// Base URL Dio sudah menyertakan `/api/v1`, jadi path ditulis relatif.
///
/// Urutan route backend: `prefix('pendaftaran')` didaftarkan SEBELUM
/// `GET /{id}`, sehingga `/ekstrakurikuler/pendaftaran/...` aman dan tidak
/// tertelan route wildcard `{id}`.
class EkstrakurikulerRemoteDataSourceImpl
    implements EkstrakurikulerRemoteDataSource {
  final Dio _dio;

  const EkstrakurikulerRemoteDataSourceImpl(this._dio);

  static const String _base = '/ekstrakurikuler';
  static const String _pendaftaran = '/ekstrakurikuler/pendaftaran';

  /// Envelope backend punya tiga bentuk:
  /// - `{ "rowData": [...] }`  → mode AG-Grid (dikirim `startRow`/`endRow`)
  /// - `{ "data": [...] }`     → resource collection / paginatedResponse
  /// - `{ "data": { "data": [...] } }` → paginator ter-nest
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

  Map<String, dynamic>? _extractMap(dynamic body) {
    if (body is! Map) return null;
    final raw = body['data'];
    if (raw is Map<String, dynamic>) return raw;
    return null;
  }

  List<EkstrakurikulerModel> _parseEkskul(dynamic body) {
    final hasil = <EkstrakurikulerModel>[];
    for (final item in _extractList(body)) {
      if (item is Map<String, dynamic>) {
        hasil.add(EkstrakurikulerModel.fromJson(item));
      }
    }
    return hasil;
  }

  List<PendaftaranEkskulModel> _parsePendaftaran(dynamic body) {
    final hasil = <PendaftaranEkskulModel>[];
    for (final item in _extractList(body)) {
      if (item is Map<String, dynamic>) {
        hasil.add(PendaftaranEkskulModel.fromJson(item));
      }
    }
    return hasil;
  }

  // ── Ekstrakurikuler ────────────────────────────────────────────────────────

  @override
  Future<List<EkstrakurikulerModel>> getEkstrakurikulerAktif() async {
    final response = await _dio.get('$_base/aktif');
    return _parseEkskul(response.data);
  }

  @override
  Future<List<EkstrakurikulerModel>> getEkstrakurikulerList({
    String? status,
    String? search,
  }) async {
    // `startRow`/`endRow` dikirim supaya relasi `pembina` ikut ter-load dan
    // filter `search` benar-benar diterapkan service (jalur AG-Grid).
    final response = await _dio.get(
      _base,
      queryParameters: <String, dynamic>{
        'startRow': 0,
        'endRow': 300,
        if (status != null && status.isNotEmpty) 'status': status,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      },
    );
    return _parseEkskul(response.data);
  }

  @override
  Future<EkstrakurikulerModel> getEkstrakurikulerDetail(int id) async {
    final response = await _dio.get('$_base/$id');
    final raw = _extractMap(response.data);
    if (raw == null || raw.isEmpty) {
      throw const NotFoundException('Detail ekstrakurikuler tidak tersedia');
    }
    return EkstrakurikulerModel.fromJson(raw);
  }

  @override
  Future<EkstrakurikulerStatistikModel> getStatistik(int id) async {
    final response = await _dio.get('$_base/$id/statistik');
    final raw = _extractMap(response.data);
    if (raw == null || raw.isEmpty) {
      return const EkstrakurikulerStatistikModel();
    }
    return EkstrakurikulerStatistikModel.fromJson(raw);
  }

  @override
  Future<List<EkstrakurikulerModel>> getByPembina(int pembinaGuruId) async {
    final response = await _dio.get('$_base/pembina/$pembinaGuruId');
    return _parseEkskul(response.data);
  }

  // ── Pendaftaran ────────────────────────────────────────────────────────────

  @override
  Future<List<PendaftaranEkskulModel>> getPesertaByEkstrakurikuler(
    int ekstrakurikulerId,
  ) async {
    final response = await _dio.get(
      '$_pendaftaran/ekstrakurikuler/$ekstrakurikulerId',
    );
    return _parsePendaftaran(response.data);
  }

  @override
  Future<List<PendaftaranEkskulModel>> getPendaftaranBySiswa(
    int siswaId,
  ) async {
    final response = await _dio.get('$_pendaftaran/siswa/$siswaId');
    return _parsePendaftaran(response.data);
  }

  @override
  Future<List<PendaftaranEkskulModel>> getRiwayatBySiswa(int siswaId) async {
    final response = await _dio.get('$_pendaftaran/siswa/$siswaId/riwayat');
    return _parsePendaftaran(response.data);
  }

  @override
  Future<List<PendaftaranEkskulModel>> getPendaftaranList({
    int? siswaId,
    int? ekstrakurikulerId,
    String? status,
  }) async {
    final response = await _dio.get(
      _pendaftaran,
      queryParameters: <String, dynamic>{
        'startRow': 0,
        'endRow': 300,
        'siswa_id': ?siswaId,
        'ekstrakurikuler_id': ?ekstrakurikulerId,
        if (status != null && status.isNotEmpty) 'status': status,
      },
    );
    return _parsePendaftaran(response.data);
  }

  @override
  Future<PendaftaranEkskulModel> daftar({
    required int ekstrakurikulerId,
    required int siswaId,
  }) async {
    final response = await _dio.post(
      _pendaftaran,
      data: <String, dynamic>{
        'ekstrakurikuler_id': ekstrakurikulerId,
        'siswa_id': siswaId,
      },
    );
    final raw = _extractMap(response.data);
    if (raw == null) {
      throw const ServerException('Respons pendaftaran tidak dikenali');
    }
    return PendaftaranEkskulModel.fromJson(raw);
  }

  @override
  Future<bool> checkStatus({
    required int siswaId,
    required int ekstrakurikulerId,
  }) async {
    final response = await _dio.post(
      '$_pendaftaran/check-status',
      data: <String, dynamic>{
        'siswa_id': siswaId,
        'ekstrakurikuler_id': ekstrakurikulerId,
      },
    );
    final raw = _extractMap(response.data);
    return raw?['terdaftar'] == true;
  }

  @override
  Future<PendaftaranEkskulModel> keluar(int pendaftaranId) async {
    final response = await _dio.post('$_pendaftaran/$pendaftaranId/keluar');
    final raw = _extractMap(response.data);
    if (raw == null) {
      throw const ServerException('Respons keluar ekskul tidak dikenali');
    }
    return PendaftaranEkskulModel.fromJson(raw);
  }
}
