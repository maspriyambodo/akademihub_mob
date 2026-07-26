import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../models/organisasi_detail_model.dart';
import '../models/organisasi_model.dart';

abstract class OrganisasiRemoteDataSource {
  Future<List<OrganisasiModel>> getOrganisasiList({String? status});
  Future<OrganisasiDetailModel> getOrganisasiDetail(int id);
}

/// Base URL Dio sudah menyertakan `/api/v1`, jadi path ditulis relatif.
///
/// Route backend (`routes/api.php` grup `prefix('organisasi')`):
/// - `GET /organisasi`         — index (AgGridControllerTrait), izin `organisasi.view`
/// - `GET /organisasi/{id}`    — detail + `anggota.jabatan` + `anggota.siswa`,
///   izin `organisasi.view`
///
/// Endpoint `/organisasi/jabatan/*` TIDAK dipakai: role siswa/wali tidak punya
/// `organisasi.jabatan.view` (verifikasi RbacSeeder). Hierarki jabatan diambil
/// dari relasi `anggota.jabatan` (field `urutan`) di endpoint detail.
class OrganisasiRemoteDataSourceImpl implements OrganisasiRemoteDataSource {
  final Dio _dio;

  const OrganisasiRemoteDataSourceImpl(this._dio);

  static const String _base = '/organisasi';

  /// Envelope backend punya tiga bentuk:
  /// - `{ "rowData": [...] }`          → mode AG-Grid (dikirim `startRow`/`endRow`)
  /// - `{ "data": [...] }`             → successResponse dengan list
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

  @override
  Future<List<OrganisasiModel>> getOrganisasiList({String? status}) async {
    // `startRow`/`endRow` dikirim agar jalur AG-Grid dipakai: relasi `pembina`
    // ikut ter-load dan filter `status`/`search` benar-benar diterapkan
    // service (OrganisasiService::applyAgGridAwareFilters).
    final response = await _dio.get(
      _base,
      queryParameters: <String, dynamic>{
        'startRow': 0,
        'endRow': 300,
        if (status != null && status.isNotEmpty) 'status': status,
      },
    );

    final hasil = <OrganisasiModel>[];
    for (final item in _extractList(response.data)) {
      if (item is Map<String, dynamic>) {
        hasil.add(OrganisasiModel.fromJson(item));
      }
    }
    return hasil;
  }

  @override
  Future<OrganisasiDetailModel> getOrganisasiDetail(int id) async {
    final response = await _dio.get('$_base/$id');
    final raw = _extractMap(response.data);
    if (raw == null || raw.isEmpty) {
      throw const NotFoundException('Detail organisasi tidak tersedia');
    }
    return OrganisasiDetailModel.fromJson(raw);
  }
}
