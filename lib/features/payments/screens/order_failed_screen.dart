import 'package:da_crust_app/features/home/screens/welcome_screen.dart';
import 'package:da_crust_app/features/payments/mixins/auto_redirect_timer_mixin.dart';
import 'package:da_crust_app/features/payments/widgets/return_to_menu_button.dart';
import 'package:flutter/material.dart';
// 🌟 Import your new mixin

class OrderFailedScreen extends StatefulWidget {
  const OrderFailedScreen({super.key});

  @override
  State<OrderFailedScreen> createState() => _OrderFailedScreenState();
}

// 🌟 Add "with AutoRedirectTimerMixin" here
class _OrderFailedScreenState extends State<OrderFailedScreen>
    with AutoRedirectTimerMixin {
  @override
  void initState() {
    super.initState();
    hasWelcomeScreenInitialized = true;
    // 🌟 Start the timer as soon as the screen loads
    startAutoRedirectTimer(
      maxSeconds: 15,
      onTick: () =>
          setState(() {}), // Refresh UI to update the countdown number
      onComplete: () {
        if (ModalRoute.of(context)?.isCurrent == true) {
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Colors.deepOrange.shade600;
    final backgroundColor = Colors.grey.shade50;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.cancel_rounded,
                      color: Colors.red.shade500,
                      size: 72,
                    ),
                  ),
                  const SizedBox(height: 32),

                  const Text(
                    'Payment Canceled',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: 0.04,
                          ), // Modern opacity syntax
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Text(
                      "Your payment was declined or canceled.\n\nDon't worry, no charges were made to your account, and your items are still safely in your cart.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                        height: 1.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 48),
                  ReturnToMenuButton(
                    countdown: countdown,
                    primaryColor: primaryColor,
                    onPressed: () {
                      hasWelcomeScreenInitialized = true;
                      cancelAutoRedirectTimer(); // Stop timer if user clicks manually
                      Navigator.of(
                        context,
                      ).pushNamedAndRemoveUntil('/', (route) => false);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
