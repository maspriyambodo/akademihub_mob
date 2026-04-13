import 'package:dio/dio.dart';
import '../models/tenant_model.dart';

/// Memanggil endpoint publik di central API untuk resolve tenant.
/// Endpoint: GET https://app.akademihub.id/api/v1/ppdb/public/sekolah
/// (digunakan kembali karena sudah ada di backend, atau bisa endpoint khusus)
abstract class TenantRemoteDataSource {
  Future<TenantModel> resolveTenant(String identifier);
  Future<List<TenantModel>> listTenants({String? query});
}

class TenantRemoteDataSourceImpl implements TenantRemoteDataSource {
  final Dio _dio;

  const TenantRemoteDataSourceImpl(this._dio);

  @override
  Future<TenantModel> resolveTenant(String identifier) async {
    final response = await _dio.get(
      '/ppdb/public/sekolah',
      queryParameters: {'identifier': identifier},
    );
    final data = response.data['data'];
    // Jika API mengembalikan array, ambil hasil pertama yang cocok
    if (data is List) {
      final match = data.firstWhere(
        (e) =>
            (e['identifier'] as String?)?.toLowerCase() ==
                identifier.toLowerCase() ||
            (e['subdomain'] as String?)?.toLowerCase() ==
                identifier.toLowerCase(),
        orElse: () => throw DioException(
          requestOptions: response.requestOptions,
          response: Response(
            requestOptions: response.requestOptions,
            statusCode: 404,
            data: {'message': 'Sekolah tidak ditemukan'},
          ),
          type: DioExceptionType.badResponse,
        ),
      );
      return TenantModel.fromJson(match as Map<String, dynamic>);
    }
    return TenantModel.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<List<TenantModel>> listTenants({String? query}) async {
    final response = await _dio.get(
      '/ppdb/public/sekolah',
      queryParameters: {if (query != null && query.isNotEmpty) 'search': query},
    );
    final data = response.data['data'];
    final list = data is List ? data : (data['data'] as List? ?? []);
    return list
        .map((e) => TenantModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
