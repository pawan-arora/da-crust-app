import 'dart:async';
import 'package:da_crust_app/data/model/order_details.dart';
import 'package:da_crust_app/features/home/screens/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';

import 'package:da_crust_app/core/utils/string_utils.dart';
import 'package:da_crust_app/features/payments/mixins/auto_redirect_timer_mixin.dart';
import 'package:da_crust_app/features/payments/widgets/return_to_menu_button.dart';
import 'package:da_crust_app/features/cart/state/cart_manager.dart';
import 'package:da_crust_app/features/payments/services/order_database_service.dart';

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
  
  // 🌟 The UI only talks to the Service now
  final OrderDatabaseService _dbService = OrderDatabaseService();

  bool _isLoading = true;
  bool _isTakingTooLong = false;
  bool _isVerifying = false; 
  bool _hasProcessedSuccess = false;

  late ConfettiController _confettiController;
  
  // 🌟 Listening to clean OrderDetails, not raw Firebase snapshots
  StreamSubscription<OrderDetails>? _orderSubscription;

  @override
  void initState() {
    super.initState();
    hasHomeScreenInitialized = true;
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    _listenToOrderStatus();

    // Show verification fallback button after 5 seconds if the bank is hanging
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _isLoading) setState(() => _isTakingTooLong = true);
    });
  }

  @override
  void dispose() {
    _orderSubscription?.cancel();
    _confettiController.dispose();
    super.dispose();
  }

  void _triggerRedirectTimer() {
    startAutoRedirectTimer(
      maxSeconds: 15,
      onTick: () => setState(() {}),
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

    _orderSubscription = _dbService.listenToOrder(widget.orderId).listen(
      (orderDetails) {
        if (orderDetails.exists) {
          final status = orderDetails.status;

          if (status == 'PAID') {
            if (!_hasProcessedSuccess) {
              _hasProcessedSuccess = true;
              
              // Safely clear the cart only once
              CartManager.instance.clearCart();

              setState(() {
                _fetchedTime = orderDetails.scheduledTime;
                _customerEmail = orderDetails.customerEmail;
                _customerPhone = orderDetails.customerPhone;
                _isLoading = false;
              });
              
              _confettiController.play();
              _triggerRedirectTimer();
            }
          } else if (status == 'FAILED' || status == 'DECLINED') {
            cancelAutoRedirectTimer();
            _orderSubscription?.cancel();
            if (!mounted) return;
            Navigator.of(context).pushNamedAndRemoveUntil('/failed', (route) => false);
          } else {
            // Still PENDING or CREATED
            if (mounted) setState(() => _isLoading = true);
          }
        } else {
          // Document does not exist yet
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

  Future<void> _verifyPaymentManually() async {
    setState(() => _isVerifying = true);
    try {
      // 🌟 Clean Service Call
      final status = await _dbService.verifyEftposStatus(widget.orderId);
      
      if (status == 'PENDING' || status == 'CREATED' || status == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Payment is still pending. Please check your bank app.")),
        );
      }
    } catch (e) {
      debugPrint("Verification failed: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Unable to verify payment at this time. Please wait.")),
      );
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
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

                      // 🌟 Polling Fallback UI
                      if (_isTakingTooLong) ...[
                        const SizedBox(height: 40),
                        _isVerifying
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : OutlinedButton.icon(
                                onPressed: _verifyPaymentManually,
                                icon: const Icon(Icons.refresh),
                                label: const Text("Still waiting? Verify Payment"),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: primaryColor,
                                  side: BorderSide(color: primaryColor.withOpacity(0.5)),
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                ),
                              ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () {
                            cancelAutoRedirectTimer();
                            _orderSubscription?.cancel();
                            Navigator.of(context).pushNamedAndRemoveUntil('/failed', (route) => false);
                          },
                          child: Text(
                            "Cancel Payment",
                            style: TextStyle(color: Colors.red.shade400),
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
                                hasHomeScreenInitialized = true;
                                cancelAutoRedirectTimer(); 
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