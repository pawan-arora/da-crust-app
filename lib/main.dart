import 'dart:ui';
import 'package:da_crust_app/app_config.dart';
import 'package:da_crust_app/core/routes/app_router.dart';
import 'package:da_crust_app/core/theme/app_theme.dart';
import 'package:da_crust_app/features/cart/state/cart_manager.dart';
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

  await CartManager.instance.initialize();
  
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
