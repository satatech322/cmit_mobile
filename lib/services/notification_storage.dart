import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationStorage {
  static const String _keyNotifications = 'cached_notifications';
  static const String _keyFcmToken = 'fcm_token';

  static SharedPreferences? _prefs;

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
  }

  static Future<List<Map<String, dynamic>>> getAllNotifications() async {
    await _init();
    final raw = _prefs?.getString(_keyNotifications);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.cast<Map<String, dynamic>>();
  }

  static Future<void> markAsRead(int index) async {
    await _init();
    final notifications = await getAllNotifications();
    if (index < notifications.length) {
      notifications[index]['is_read'] = true;
      await _prefs?.setString(
        _keyNotifications,
        jsonEncode(notifications),
      );
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
  }

  static Future<void> clearAll() async {
    await _init();
    await _prefs?.remove(_keyNotifications);
  }
}
