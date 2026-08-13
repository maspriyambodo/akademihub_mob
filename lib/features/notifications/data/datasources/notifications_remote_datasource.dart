import 'package:dio/dio.dart';

import '../models/notification_model.dart';
import '../models/notification_page_model.dart';

abstract class NotificationsRemoteDataSource {
  Future<NotificationPageModel> getNotifications({int page, int perPage});
  Future<int> getUnreadCount();
  Future<NotificationModel?> markAsRead(int id);
  Future<int> markAllAsRead();
}

class NotificationsRemoteDataSourceImpl
    implements NotificationsRemoteDataSource {
  final Dio _dio;

  const NotificationsRemoteDataSourceImpl(this._dio);

  @override
  Future<NotificationPageModel> getNotifications({
    int page = 1,
    int perPage = 20,
  }) async {
    final response = await _dio.get(
      '/notifikasi',
      queryParameters: {'page': page, 'per_page': perPage},
    );
    return NotificationPageModel.fromResponse(
      _asMap(response.data),
      fallbackPerPage: perPage,
    );
  }

  @override
  Future<int> getUnreadCount() async {
    final response = await _dio.get('/notifikasi/unread-count');
    final data = _asMap(response.data)['data'];
    if (data is Map) {
      return (data['unread_count'] as num?)?.toInt() ?? 0;
    }
    return (data as num?)?.toInt() ?? 0;
  }

  @override
  Future<NotificationModel?> markAsRead(int id) async {
    final response = await _dio.put('/notifikasi/$id/read');
    final data = _asMap(response.data)['data'];
    if (data is Map<String, dynamic>) {
      return NotificationModel.fromJson(data);
    }
    return null;
  }

  @override
  Future<int> markAllAsRead() async {
    final response = await _dio.post('/notifikasi/read-all');
    final data = _asMap(response.data)['data'];
    if (data is Map) {
      return (data['updated'] as num?)?.toInt() ?? 0;
    }
    return 0;
  }

  Map<String, dynamic> _asMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return raw.map((k, v) => MapEntry(k.toString(), v));
    return <String, dynamic>{};
  }
}
