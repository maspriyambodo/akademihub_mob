import 'package:dio/dio.dart';
import '../models/dashboard_model.dart';

abstract class DashboardRemoteDataSource {
  Future<DashboardModel> getDashboardData();
}

class DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
  final Dio _dio;

  const DashboardRemoteDataSourceImpl(this._dio);

  @override
  Future<DashboardModel> getDashboardData() async {
    final response = await _dio.get('/dashboard/');
    final data = response.data['data'] as Map<String, dynamic>;
    return DashboardModel.fromJson(data);
  }
}
