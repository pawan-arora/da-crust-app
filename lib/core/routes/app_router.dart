import 'dart:ui';
import 'package:da_crust_app/features/cart/screens/checkout_screen.dart';
import 'package:da_crust_app/features/home/screens/welcome_screen.dart';
import 'package:flutter/material.dart';

import 'package:da_crust_app/features/payments/screens/order_success_screen.dart';
import 'package:da_crust_app/features/payments/screens/order_failed_screen.dart';

class AppRouter {
  // 🌟 Track if we've checked the startup URL yet for Flutter Web deep linking
  static bool _initialRouteChecked = false;

  static Route<dynamic> generateRoute(RouteSettings settings) {
    // 🌟 1. Check if the app was launched directly via a deep link (e.g., returning from Stripe)
    if (!_initialRouteChecked) {
      _initialRouteChecked = true;
      // defaultRouteName gets the exact URL the browser initially loaded
      final initialUrl = PlatformDispatcher.instance.defaultRouteName;
      if (initialUrl != '/' && initialUrl.isNotEmpty) {
        hasHomeScreenInitialized = true; // Force WelcomeScreen to bypass animations
      }
    }

    final uri = Uri.parse(settings.name ?? '/');

    // 🌟 2. Keep standard safety check for standard in-app navigation
    if (uri.path != '/') {
      hasHomeScreenInitialized = true;
    }
    
    switch (uri.path) {
      case '/':
        return _buildHomeRoute(settings);

      case '/checkout':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const CheckoutScreen(),
        );
        
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
      builder: (context) => const WelcomeScreen(), 
    );
  }
}