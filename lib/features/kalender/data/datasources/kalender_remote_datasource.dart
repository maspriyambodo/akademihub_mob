import 'package:dio/dio.dart';

import '../models/kalender_event_model.dart';
import '../models/kalender_harian_model.dart';
import '../models/kalender_konteks_model.dart';
import '../models/kalender_tipe_model.dart';

/// Semua endpoint kalender berada di grup `admin` → `/api/v1/admin/...`.
/// Base URL Dio sudah memuat `/api/v1`, jadi path di sini relatif.
///
/// Rute persis (routes/api.php baris 657–703, di dalam
/// `Route::prefix('v1') > middleware(['auth:api','tenant']) > prefix('admin')`):
/// - `GET /admin/tahun-ajaran`            → permission `tahun-ajaran.view`
/// - `GET /admin/tahun-ajaran/active`     → permission `tahun-ajaran.view`
/// - `GET /admin/semester`                → permission `semester.view`
/// - `GET /admin/hari-operasional`        → permission `hari-operasional.view`
/// - `GET /admin/kalender-tipe`           → permission `kalender-tipe.view`
/// - `GET /admin/kalender-akademik`       → permission `kalender-akademik.view`
/// - `GET /admin/kalender-harian`         → permission `kalender-harian.view`
abstract class KalenderRemoteDataSource {
  Future<List<KalenderEventModel>> getEvents({int limit});
  Future<List<KalenderHarianModel>> getHarian({int limit});
  Future<List<KalenderTipeModel>> getTipeList();
  Future<TahunAjaranModel?> getTahunAjaranAktif();
  Future<List<SemesterModel>> getSemesterList();
  Future<List<HariOperasionalModel>> getHariOperasional();
}

class KalenderRemoteDataSourceImpl implements KalenderRemoteDataSource {
  final Dio _dio;

  const KalenderRemoteDataSourceImpl(this._dio);

  /// Semua controller kalender memakai `AgGridControllerTrait`, jadi bentuk
  /// response bisa tiga macam:
  /// - `{ "rowData": [...] }`        → bila `startRow`/`endRow` dikirim
  /// - `{ "data": [...] }`           → paginasi biasa
  /// - `{ "data": { "data": [...] } }`
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

  List<T> _parseList<T>(dynamic body, T Function(Map<String, dynamic>) build) {
    final hasil = <T>[];
    for (final item in _extractList(body)) {
      if (item is Map<String, dynamic>) hasil.add(build(item));
    }
    return hasil;
  }

  /// AG-Grid membaca `sortModel` sebagai array bersarang. Kunci ditulis datar
  /// (`sortModel[0][colId]`) supaya encoding Dio → PHP tetap benar.
  Map<String, dynamic> _query({
    required int limit,
    String? sortColumn,
    String sortDirection = 'desc',
  }) => <String, dynamic>{
    'startRow': 0,
    'endRow': limit,
    if (sortColumn != null) ...{
      'sortModel[0][colId]': sortColumn,
      'sortModel[0][sort]': sortDirection,
    },
  };

  @override
  Future<List<KalenderEventModel>> getEvents({int limit = 500}) async {
    // Mode AG-Grid dipakai supaya bisa mengurutkan berdasarkan tanggal_mulai;
    // mode paginasi biasa memakai cursorPaginate tanpa kendali urutan.
    final response = await _dio.get(
      '/admin/kalender-akademik',
      queryParameters: _query(limit: limit, sortColumn: 'tanggal_mulai'),
    );
    return _parseList(response.data, KalenderEventModel.fromJson);
  }

  @override
  Future<List<KalenderHarianModel>> getHarian({int limit = 500}) async {
    // WAJIB mode AG-Grid: hanya jalur ini yang meng-eager-load relasi
    // `kalender`, sumber judul event induk.
    final response = await _dio.get(
      '/admin/kalender-harian',
      queryParameters: _query(limit: limit, sortColumn: 'tanggal'),
    );
    return _parseList(response.data, KalenderHarianModel.fromJson);
  }

  @override
  Future<List<KalenderTipeModel>> getTipeList() async {
    final response = await _dio.get(
      '/admin/kalender-tipe',
      queryParameters: _query(
        limit: 200,
        sortColumn: 'nama',
        sortDirection: 'asc',
      ),
    );
    return _parseList(response.data, KalenderTipeModel.fromJson);
  }

  @override
  Future<TahunAjaranModel?> getTahunAjaranAktif() async {
    final response = await _dio.get('/admin/tahun-ajaran/active');
    final raw = response.data is Map ? response.data['data'] : null;
    if (raw is! Map<String, dynamic> || raw.isEmpty) return null;
    return TahunAjaranModel.fromJson(raw);
  }

  @override
  Future<List<SemesterModel>> getSemesterList() async {
    final response = await _dio.get(
      '/admin/semester',
      queryParameters: _query(
        limit: 200,
        sortColumn: 'tanggal_mulai',
        sortDirection: 'desc',
      ),
    );
    return _parseList(response.data, SemesterModel.fromJson);
  }

  @override
  Future<List<HariOperasionalModel>> getHariOperasional() async {
    final response = await _dio.get(
      '/admin/hari-operasional',
      queryParameters: _query(
        limit: 20,
        sortColumn: 'id',
        sortDirection: 'asc',
      ),
    );
    return _parseList(response.data, HariOperasionalModel.fromJson);
  }
}
