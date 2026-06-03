import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // 🌟 Replace this with your actual initialization logic
    // For example: await Firebase.initializeApp(); or checking user login status
    await Future.delayed(const Duration(seconds: 3)); 

    if (!mounted) return;

    // 🌟 Once loading is done, seamlessly replace the splash screen with your main app
    Navigator.of(context).pushReplacementNamed('/'); // Or your Home/Login route
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Match this background color to your Native Splash background color
      backgroundColor: Colors.grey.shade50, 
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 🌟 Your animated GIF loader
            Image.asset(
              'assets/gif/screen_loader.gif',
              width: 200,
              height: 200,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}