import 'dart:ui';
import 'package:da_crust_app/app_config.dart';
import 'package:da_crust_app/core/routes/app_router.dart';
import 'package:da_crust_app/core/theme/app_theme.dart';
import 'package:da_crust_app/features/cart/state/cart_manager.dart';
import 'package:da_crust_app/features/home/services/restaurant_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_dotenv/flutter_dotenv.dart';

// 🌟 1. Import both configuration files with aliases
import 'firebase_options_dev.dart' as dev;
import 'firebase_options_prod.dart' as prod;

void main() async {
  tz.initializeTimeZones();
  WidgetsFlutterBinding.ensureInitialized();

  // 🌟 THE FIX: Point to the renamed file inside the assets folder
  await dotenv.load(fileName: "assets/config.env");

  // 🌟 2. Read the environment flag (Defaults to 'dev' to protect production)
  const environment = String.fromEnvironment('ENV', defaultValue: 'dev');

  // 🌟 3. Select the correct options based on the flag
  final firebaseOptions = environment == 'prod'
      ? prod.DefaultFirebaseOptions.currentPlatform
      : dev.DefaultFirebaseOptions.currentPlatform;

  // 🌟 4. Initialize Firebase with the selected options
  await Firebase.initializeApp(options: firebaseOptions);

  // Fetch the Store Settings from Firestore
  await AppConfig.instance.init();

  // Fetch open/closed status up front so it's available synchronously to
  // the router — deep links straight to routes like '/checkout' never build
  // WelcomeScreen (the only other place this used to get fetched), so
  // without this the closed-store gate below would always see stale
  // "open" defaults on a fresh page load.
  await RestaurantService.instance.init();

  await CartManager.instance.initialize();

  // Menu images are decoded at their on-screen size (see SafeMenuImage's
  // memCacheWidth/memCacheHeight), so each cached frame is small — but cap
  // the total resident count too as a backstop against unbounded growth
  // while scrolling long menus, which was pressuring CanvasKit's GPU
  // texture cache on web and causing "texImage2D: no image" repaint errors.
  PaintingBinding.instance.imageCache.maximumSize = 200;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 50 << 20; // 50 MB

  // Run the App
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Da Crust',
      theme: AppTheme.lightTheme,
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
      ),

      // 1. Tell Flutter to always start at the root
      initialRoute: '/',

      // 2. The Traffic Cop: Reads the browser's URL and routes accordingly
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}
