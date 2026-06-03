import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:url_launcher/url_launcher.dart';

enum NzPaymentMethod { card, eftpos, afterpay }

class PaymentHandler {
  static Future<void> process({
    required NzPaymentMethod method,
    required double amount,
    required String orderId,
    required int scheduledTime, 
    required String customerPhone, 
  }) async {
    try {
      switch (method) {
        case NzPaymentMethod.card:
        case NzPaymentMethod.afterpay:
          // 🌟 FIX: Pass the method name (e.g., "card" or "afterpay") down to the Stripe handler
          await _redirectToStripeCheckout(amount, orderId, scheduledTime, method.name);
          break;
        case NzPaymentMethod.eftpos:
          await _processPaymarkEftpos(amount, orderId, customerPhone);
          break;
      }
    } catch (e) {
      debugPrint("General Payment error: ${e.toString()}");
      throw Exception(e.toString()); 
    }
  }

  static Future<void> _redirectToStripeCheckout(
    double amount,
    String orderId,
    int scheduledTimeMs, 
    String paymentMethodName, // 🌟 FIX: Accept the method name here
  ) async {
    final result = await FirebaseFunctions.instanceFor(region: 'australia-southeast1')
        .httpsCallable('createCheckoutSession')
        .call({
          'amount': amount,
          'orderId': orderId,
          'scheduledTimeEpoch': scheduledTimeMs, 
          'paymentMethod': paymentMethodName, // 🌟 FIX: Send it to Firebase so it triggers the Afterpay UI!
        });

    final String checkoutUrl = result.data['url'] as String;
    final Uri uri = Uri.parse(checkoutUrl);
    
    if (!await launchUrl(uri, webOnlyWindowName: '_self')) {
      throw Exception("Could not redirect to Stripe payment gateway.");
    }
  }

  static Future<void> _processPaymarkEftpos(
    double amount,
    String orderId,
    String customerPhone,
  ) async {
    final result = await FirebaseFunctions.instanceFor(region: 'australia-southeast1')
        .httpsCallable('createOnlineEftposSession')
        .call({
          'amount': amount,
          'orderId': orderId,
          'mobileNumber': customerPhone, 
        });

    final String waitingPageUrl = result.data['url'] as String;
    final Uri uri = Uri.parse(waitingPageUrl);
    
    if (!await launchUrl(uri, webOnlyWindowName: '_self')) {
      throw Exception("Could not open Online EFTPOS gateway.");
    }
  }
}