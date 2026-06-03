import 'dart:async';
import 'package:flutter/material.dart';

mixin AutoRedirectTimerMixin<T extends StatefulWidget> on State<T> {
  Timer? _redirectTimer;
  int countdown = 15; // Default starting time
  bool _isTimerStarted = false;

  void startAutoRedirectTimer({
    required int maxSeconds,
    required VoidCallback onTick,
    required VoidCallback onComplete,
  }) {
    if (_isTimerStarted) return;
    _isTimerStarted = true;
    countdown = maxSeconds;

    _redirectTimer?.cancel();
    final endTime = DateTime.now().add(Duration(seconds: maxSeconds));

    _redirectTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final now = DateTime.now();
      final secondsLeft = endTime.difference(now).inSeconds;

      if (secondsLeft > 0) {
        countdown = secondsLeft;
        onTick(); // Tells the UI to rebuild
      } else {
        timer.cancel();
        onComplete(); // Triggers the navigation
      }
    });
  }

  void cancelAutoRedirectTimer() {
    _redirectTimer?.cancel();
    _isTimerStarted = false;
  }

  @override
  void dispose() {
    // 🌟 Automatically cleans up the timer when the screen is destroyed!
    _redirectTimer?.cancel();
    super.dispose();
  }
}