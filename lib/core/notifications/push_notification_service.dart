import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class PushNotificationService {
  final Dio _dio;
  FirebaseMessaging? _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications;

  StreamSubscription<String>? _tokenSubscription;
  StreamSubscription<RemoteMessage>? _messageSubscription;
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
      );
      await _messaging!.requestPermission();
      _messageSubscription = FirebaseMessaging.onMessage.listen(_showMessage);
      _tokenSubscription = _messaging!.onTokenRefresh.listen(_registerToken);
      _available = true;
    } on Object catch (error) {
      if (kDebugMode) debugPrint('Push notification unavailable: $error');
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
    );
  }

  Future<void> dispose() async {
    await _tokenSubscription?.cancel();
    await _messageSubscription?.cancel();
  }
}
