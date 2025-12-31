import 'package:flutter/material.dart';
import 'package:cmit/features/splash/view/splash_screen.dart';
import 'package:cmit/features/auth/view/login_screen.dart';
import 'package:cmit/features/auth/view/onboarding_screen.dart'; // Updated to OnboardingScreen

import 'package:cmit/features/home/view/home_screen.dart';

class Routes {
  /// ✅ **Define Route Names**
  static const String initial = '/';
  static const String welcome = '/welcome';
  static const String login = '/subscription';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String otpVerification = '/otp-verification';
  static const String newPasswordScreen = '/new-password';
  static const String home = '/home';
  static const String securitySettings = '/security-settings';
  static const String favorites = '/favorites';
  static const String bookings = '/bookings';

  static const String settings = '/settings';
  static const String generatedVouchers = '/generated-vouchers';

  /// ✅ **Define Named Routes**
  static Map<String, WidgetBuilder> getRoutes() {
    return {
      initial: (context) => SplashScreen(),
      welcome: (context) => OnboardingScreen(), // Updated to OnboardingScreen
      login: (context) => LoginScreen(),

      home: (context) => HomeScreen(),
    };
  }

  /// ✅ **Dynamic Navigation Handling**
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    print("🔹 Navigating to: ${settings.name}");

    switch (settings.name) {
      case Routes.initial:
        return MaterialPageRoute(builder: (_) => SplashScreen());
      case Routes.welcome:
        return MaterialPageRoute(builder: (_) => OnboardingScreen()); // Updated to OnboardingScreen
      case Routes.login:
        return MaterialPageRoute(builder: (_) => LoginScreen());

      case Routes.home:
        return MaterialPageRoute(builder: (_) => HomeScreen());

    // Other routes like securitySettings, favorites, bookings are not handled here yet
    // They will fall through to default (404) for now
      default:
        print("❌ ERROR: Undefined Route - ${settings.name}");
        return _errorRoute();
    }
  }

  /// ✅ **Handle Unknown Routes**
  static Route<dynamic> onUnknownRoute(RouteSettings settings) {
    print("⚠️ Unknown Route Attempted: ${settings.name}");
    return _errorRoute();
  }

  /// 🚀 **Reusable 404 Error Page**
  static MaterialPageRoute _errorRoute() {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        body: Center(
          child: Text(
            "🚫 404 - Page Not Found",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
          ),
        ),
      ),
    );
  }
}