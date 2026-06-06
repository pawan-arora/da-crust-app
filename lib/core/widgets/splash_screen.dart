import 'package:flutter/material.dart';
import 'package:da_crust_app/features/home/screens/home_screen.dart';

// Tracks if the splash has been shown during this browser session
bool hasAppInitialized = false;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Only run the timer if the app hasn't initialized yet
    if (!hasAppInitialized) {
      _initializeApp();
    }
  }

  Future<void> _initializeApp() async {
    // Put any actual initialization logic here (Firebase, Configs, etc.)
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    // 🌟 Swap the UI to the Home Screen WITHOUT touching the Navigator
    setState(() {
      hasAppInitialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 🌟 If initialized (or user returned to menu), instantly render the Home Screen
    if (hasAppInitialized) {
      return const HomeScreen();
    }

   var name = 'assets/gif/screen_loader.gif';
   return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SizedBox(
          width: double.infinity,
          child: Image.asset(
            name,
            fit: BoxFit.fitWidth, 
          ),
        ),
      ),
    );
  }
}