import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../router/app_router.dart';

class PushNotificationService {
  final Dio _dio;
  FirebaseMessaging? _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications;

  StreamSubscription<String>? _tokenSubscription;
  StreamSubscription<RemoteMessage>? _messageSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;
  bool _available = false;

  PushNotificationService(
    this._dio, {
    FirebaseMessaging? messaging,
    FlutterLocalNotificationsPlugin? localNotifications,
  }) : _messaging = messaging,
       _localNotifications =
           localNotifications ?? FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
      _messaging ??= FirebaseMessaging.instance;
      await _localNotifications.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
        onDidReceiveNotificationResponse: (response) {
          final payload = response.payload;
          if (payload != null && payload.isNotEmpty) {
            _handleRoute(payload);
          }
        },
      );
      await _messaging!.requestPermission();
      _messageSubscription = FirebaseMessaging.onMessage.listen(_showMessage);
      _tokenSubscription = _messaging!.onTokenRefresh.listen(_registerToken);

      _openedSubscription =
          FirebaseMessaging.onMessageOpenedApp.listen((message) {
            final route = _resolveRoute(message.data);
            _handleRoute(route);
          });

      final initialMessage = await _messaging!.getInitialMessage();
      if (initialMessage != null) {
        final route = _resolveRoute(initialMessage.data);
        if (route != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _handleRoute(route);
          });
        }
      }

      _available = true;
    } on Object catch (error) {
      if (kDebugMode) debugPrint('Push notification unavailable: $error');
    }
  }

  String? _resolveRoute(Map<String, dynamic> data) {
    final explicitRoute = data['route']?.toString();
    if (explicitRoute != null && explicitRoute.isNotEmpty) {
      return explicitRoute;
    }
    final type = data['type']?.toString();
    return switch (type) {
      'absensi' || 'absensi_kritis' => AppRoutes.absensi,
      'spp' || 'spp_tunggakan' || 'keuangan' => AppRoutes.keuangan,
      'ews_alert' || 'ews' => AppRoutes.ews,
      'tugas' || 'tugas_baru' => AppRoutes.tugas,
      'nilai' || 'nilai_anomali' => AppRoutes.nilai,
      'jadwal' => AppRoutes.jadwal,
      'ujian' => AppRoutes.ujian,
      'wallet' || 'saldo' => AppRoutes.wallet,
      _ => null,
    };
  }

  void _handleRoute(String? route) {
    if (route == null || route.isEmpty) return;
    try {
      router.push(route);
    } catch (e) {
      if (kDebugMode) debugPrint('FCM navigation error: $e');
    }
  }

  Future<void> syncToken() async {
    if (!_available) return;
    final token = await _messaging!.getToken();
    if (token != null) await _registerToken(token);
  }

  Future<void> unregisterToken() async {
    if (!_available) return;
    try {
      await _dio.delete('/fcm/token');
    } on DioException catch (error) {
      if (kDebugMode) debugPrint('FCM token unregister failed: $error');
    }
  }

  Future<void> _registerToken(String token) async {
    try {
      await _dio.post('/fcm/token', data: {'token': token});
    } on DioException catch (error) {
      if (kDebugMode) debugPrint('FCM token register failed: $error');
    }
  }

  Future<void> _showMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;
    final route = _resolveRoute(message.data);
    await _localNotifications.show(
      message.messageId.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'akademihub_notifications',
          'Notifikasi AkademiHub',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: route,
    );
  }

  Future<void> dispose() async {
    await _tokenSubscription?.cancel();
    await _messageSubscription?.cancel();
    await _openedSubscription?.cancel();
  }
}
