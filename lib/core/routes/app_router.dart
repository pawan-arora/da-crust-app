import 'package:da_crust_app/features/home/screens/welcome_screen.dart';
import 'package:flutter/material.dart';

// 🌟 Import the SplashScreen
import 'package:da_crust_app/features/payments/screens/order_success_screen.dart';
import 'package:da_crust_app/features/payments/screens/order_failed_screen.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final uri = Uri.parse(settings.name ?? '/');

    switch (uri.path) {
      case '/':
        return _buildHomeRoute(settings);
      case '/success':
        return _buildSuccessRoute(uri, settings);
      case '/failed':
        return _buildFailedRoute(settings);
      default:
        return _buildHomeRoute(const RouteSettings(name: '/'));
    }
  }

  static Route<dynamic> _buildSuccessRoute(Uri uri, RouteSettings settings) {
    final String orderId = uri.queryParameters['orderId'] ?? 'Unknown Order';

    return MaterialPageRoute(
      settings: settings,
      builder: (context) => OrderSuccessScreen(orderId: orderId),
    );
  }

  static Route<dynamic> _buildFailedRoute(RouteSettings settings) {
    return MaterialPageRoute(
      settings: settings,
      builder: (context) => const OrderFailedScreen(),
    );
  }

  static Route<dynamic> _buildHomeRoute(RouteSettings settings) {
    return MaterialPageRoute(
      settings: settings,
      // 🌟 Point directly to the SplashScreen (which will handle routing to Home automatically)
      builder:
          (context) => //const SplashScreen(),
              const WelcomeScreen(), // Use WelcomeScreen directly for now
    );
  }
}
