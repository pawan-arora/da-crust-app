import 'dart:async';
import 'package:da_crust_app/core/utils/string_utils.dart';
import 'package:da_crust_app/core/widgets/splash_screen.dart';
import 'package:da_crust_app/features/payments/mixins/auto_redirect_timer_mixin.dart';
import 'package:da_crust_app/features/payments/state/order_repository.dart';
import 'package:da_crust_app/features/payments/widgets/return_to_menu_button.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:confetti/confetti.dart';

// 🌟 Import your new Mixin!
import 'package:da_crust_app/features/cart/state/cart_manager.dart';

class OrderSuccessScreen extends StatefulWidget {
  final String orderId;

  const OrderSuccessScreen({super.key, required this.orderId});

  @override
  State<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends State<OrderSuccessScreen>
    with AutoRedirectTimerMixin {
  String? _fetchedTime;
  String? _customerEmail;
  String? _customerPhone;
  final OrderRepository _orderRepo = OrderRepository();

  bool _isLoading = true;
  bool _isTakingTooLong = false;
  bool _hasProcessedSuccess = false; // Prevents clearing the cart twice

  late ConfettiController _confettiController;
  StreamSubscription<DocumentSnapshot>? _orderSubscription;

  @override
  void initState() {
    super.initState();
    hasAppInitialized = true;
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    _listenToOrderStatus();

    // Show cancellation fallback button after 5 seconds if Paymark is hanging
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _isLoading) setState(() => _isTakingTooLong = true);
    });
  }

  @override
  void dispose() {
    _orderSubscription?.cancel();
    _confettiController.dispose();
    // 🌟 The mixin automatically handles canceling the timer here!
    super.dispose();
  }

  // 🌟 A clean helper method to start the mixin timer
  void _triggerRedirectTimer() {
    startAutoRedirectTimer(
      maxSeconds: 15,
      onTick: () =>
          setState(() {}), // Refresh UI every second for the countdown
      onComplete: () {
        if (ModalRoute.of(context)?.isCurrent == true) {
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        }
      },
    );
  }

  void _listenToOrderStatus() {
    if (widget.orderId == 'Unknown Order') {
      setState(() => _isLoading = false);
      _triggerRedirectTimer();
      return;
    }

    _orderSubscription = _orderRepo
        .listenToOrder(widget.orderId)
        .listen(
          (snapshot) {
            if (snapshot.exists) {
              final data = snapshot.data()!;
              final status = data['status'] as String?;

              if (status == 'PAID') {
                if (!_hasProcessedSuccess) {
                  _hasProcessedSuccess = true;

                  // SAFELY CLEAR THE CART
                  CartManager.instance.clearCart();

                  setState(() {
                    _fetchedTime = data['scheduledTime'] as String?;
                    _customerEmail = data['customerEmail'] as String?;
                    _customerPhone = data['customerPhone'] as String?;
                    _isLoading = false;
                  });
                  _confettiController.play();
                  _triggerRedirectTimer();
                }
              } else if (status == 'FAILED' || status == 'DECLINED') {
                // Actively boot them to the failure screen if the bank rejects it
                cancelAutoRedirectTimer(); // 🌟 Mixin method
                _orderSubscription?.cancel();
                if (!mounted) return;
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/failed', (route) => false);
              }
            } else {
              setState(() => _isLoading = false);
              _triggerRedirectTimer();
            }
          },
          onError: (e) {
            debugPrint("Error listening to order: $e");
            setState(() => _isLoading = false);
            _triggerRedirectTimer();
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
      body: Stack(
        children: [
          _isLoading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: primaryColor),
                      const SizedBox(height: 24),
                      const Text(
                        "Confirming payment...",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Waiting for the bank to respond.",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),

                      if (_isTakingTooLong) ...[
                        const SizedBox(height: 40),
                        TextButton.icon(
                          onPressed: () {
                            cancelAutoRedirectTimer(); // 🌟 Mixin method
                            _orderSubscription?.cancel();
                            Navigator.of(context).pushNamedAndRemoveUntil(
                              '/failed',
                              (route) => false,
                            );
                          },
                          icon: const Icon(Icons.cancel_outlined),
                          label: const Text("Cancel Payment"),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                )
              : SafeArea(
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
                                color: Colors.green.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.check_circle_rounded,
                                color: Colors.green.shade500,
                                size: 72,
                              ),
                            ),
                            const SizedBox(height: 32),

                            const Text(
                              'Order Confirmed!',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: Colors.black87,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 12),

                            Text(
                              'Your food is being prepared by our kitchen.\nWe\'ve sent your complete order summary to your email and a quick confirmation text to your phone.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey.shade600,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 40),

                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 24,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildDetailRow(
                                    'Order Number',
                                    '#${widget.orderId}',
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    child: Divider(height: 1),
                                  ),
                                  _buildDetailRow(
                                    'Pickup Time',
                                    _fetchedTime ?? "Processing...",
                                    highlight: true,
                                    accentColor: primaryColor,
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    child: Divider(height: 1),
                                  ),
                                  _buildDetailRow(
                                    'Email',
                                    _customerEmail ?? "Not provided",
                                    isContactInfo: true,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildDetailRow(
                                    'Phone',
                                    StringUtils.formatNzPhoneNumber(
                                          _customerPhone,
                                        ) ??
                                        "Not Provided",
                                    isContactInfo: true,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 48),
                            ReturnToMenuButton(
                              countdown: countdown,
                              primaryColor: primaryColor,
                              onPressed: () {
                                hasAppInitialized = true;
                                cancelAutoRedirectTimer(); // 🌟 Mixin method
                                Navigator.of(context).pushNamedAndRemoveUntil(
                                  '/',
                                  (route) => false,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              emissionFrequency: 0.05,
              numberOfParticles: 50,
              gravity: 0.1,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.amber,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool highlight = false,
    Color? accentColor,
    bool isContactInfo = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            overflow: isContactInfo
                ? TextOverflow.ellipsis
                : TextOverflow.visible,
            style: TextStyle(
              fontSize: 15,
              color: highlight
                  ? (accentColor ?? Colors.black87)
                  : Colors.black87,
              fontWeight: highlight ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
