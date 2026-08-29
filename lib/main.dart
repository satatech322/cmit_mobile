import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cmit/app.dart';
import 'package:cmit/core/local_storage.dart';
import 'package:cmit/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hide system navigation bar (keep top status bar visible)
  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: [SystemUiOverlay.top],
  );

  await _initializeApp();

  NotificationService().onNotificationTapped = (data) {
    if (data == null) return;
  };

  runApp(const CmitApp());
}

Future<void> _initializeApp() async {
  try {
    await Firebase.initializeApp();
    await LocalStorage.init();
    await NotificationService().initialize();
  } catch (e) {
    debugPrint('Failed to initialize app: $e');
  }
}