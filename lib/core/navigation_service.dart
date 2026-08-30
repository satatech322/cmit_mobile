import 'package:flutter/material.dart';
import 'package:cmit/config/routes.dart';
import 'package:cmit/core/local_storage.dart';

/// Global Navigation Service providing access to navigator state and centralized logout redirection
class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  static BuildContext? get currentContext => navigatorKey.currentContext;

  static bool _isLoggingOut = false;

  /// Clears local session and redirects user to Login screen
  static Future<void> forceLogoutToLogin({String message = "Session expired. Please log in again."}) async {
    if (_isLoggingOut) return;
    _isLoggingOut = true;

    try {
      await LocalStorage.logout();

      final state = navigatorKey.currentState;
      if (state != null) {
        state.pushNamedAndRemoveUntil(
          Routes.login,
          (route) => false,
        );

        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: const Color(0xFFC62828),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      Future.delayed(const Duration(seconds: 1), () {
        _isLoggingOut = false;
      });
    }
  }
}
