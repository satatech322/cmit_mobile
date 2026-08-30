import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationStorage {
  static const String _keyNotifications = 'cached_notifications';
  static const String _keyFcmToken = 'fcm_token';

  static SharedPreferences? _prefs;
  static final StreamController<void> _streamController = StreamController<void>.broadcast();

  /// Stream to listen to real-time notification changes across screens
  static Stream<void> get onNotificationsChanged => _streamController.stream;

  static void _notify() {
    if (!_streamController.isClosed) {
      _streamController.add(null);
    }
  }

  static Future<void> _init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static Future<void> saveFcmToken(String token) async {
    await _init();
    await _prefs?.setString(_keyFcmToken, token);
  }

  static Future<String?> getFcmToken() async {
    await _init();
    return _prefs?.getString(_keyFcmToken);
  }

  static Future<void> clearFcmToken() async {
    await _init();
    await _prefs?.remove(_keyFcmToken);
  }

  static Future<void> addNotification(Map<String, dynamic> notification) async {
    await _init();
    final notifications = await getAllNotifications();
    notifications.insert(0, notification);
    await _prefs?.setString(
      _keyNotifications,
      jsonEncode(notifications),
    );
    _notify();
  }

  static Future<List<Map<String, dynamic>>> getAllNotifications() async {
    await _init();
    final raw = _prefs?.getString(_keyNotifications);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  static Future<int> getUnreadCount() async {
    final notifications = await getAllNotifications();
    return notifications.where((n) => n['is_read'] != true).length;
  }

  static Future<void> markAsRead(int index) async {
    await _init();
    final notifications = await getAllNotifications();
    if (index >= 0 && index < notifications.length) {
      notifications[index]['is_read'] = true;
      await _prefs?.setString(
        _keyNotifications,
        jsonEncode(notifications),
      );
      _notify();
    }
  }

  static Future<void> markAllAsRead() async {
    await _init();
    final notifications = await getAllNotifications();
    for (final n in notifications) {
      n['is_read'] = true;
    }
    await _prefs?.setString(
      _keyNotifications,
      jsonEncode(notifications),
    );
    _notify();
  }

  static Future<void> deleteNotification(int index) async {
    await _init();
    final notifications = await getAllNotifications();
    if (index >= 0 && index < notifications.length) {
      notifications.removeAt(index);
      await _prefs?.setString(
        _keyNotifications,
        jsonEncode(notifications),
      );
      _notify();
    }
  }

  static Future<void> clearAll() async {
    await _init();
    await _prefs?.remove(_keyNotifications);
    _notify();
  }
}
