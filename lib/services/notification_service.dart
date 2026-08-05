import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cmit/core/api_service.dart';
import 'package:cmit/config/api.dart';
import 'notification_storage.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  void Function(Map<String, dynamic>? data)? onNotificationTapped;

  Future<void> initialize() async {
    await _requestPermissions();
    await _initLocalNotifications();

    final token = await _messaging.getToken();
    if (token != null) {
      await NotificationStorage.saveFcmToken(token);
    }

    _messaging.onTokenRefresh.listen((token) async {
      await NotificationStorage.saveFcmToken(token);
    });
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  Future<void> registerSavedToken() async {
    final token = await NotificationStorage.getFcmToken();
    if (token != null && token.isNotEmpty) {
      await ApiService.post(API.registerFcmToken, {'fcm_token': token});
    }
  }

  Future<void> _requestPermissions() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        if (response.payload != null) {
          final data = jsonDecode(response.payload!) as Map<String, dynamic>;
          onNotificationTapped?.call(data);
        }
      },
    );
  }

  Future<void> _registerToken(String token) async {
    await NotificationStorage.saveFcmToken(token);
    await ApiService.post(API.registerFcmToken, {'fcm_token': token});
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final data = message.data;
    final notification = message.notification;

    final payload = {
      'title': notification?.title ?? '',
      'body': notification?.body ?? '',
      'type': data['type'],
      'assessment_id': data['assessment_id'],
      'is_ms': data['is_ms'],
      'created_at': DateTime.now().toIso8601String(),
      'is_read': false,
    };

    await NotificationStorage.addNotification(payload);
    await _showLocalNotification(notification, data);
  }

  Future<void> _showLocalNotification(
    RemoteNotification? notification,
    Map<String, dynamic> data,
  ) async {
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'default_channel',
      'Default Notifications',
      channelDescription: 'General notifications',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      notification.title,
      notification.body,
      details,
      payload: jsonEncode(data),
    );
  }

  void _handleNotificationTap(RemoteMessage message) {
    onNotificationTapped?.call(message.data);
  }

  Future<void> clearToken() async {
    await ApiService.post(API.registerFcmToken, {'fcm_token': ''});
    await NotificationStorage.clearFcmToken();
  }
}
