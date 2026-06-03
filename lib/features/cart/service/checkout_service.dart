import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:da_crust_app/core/utils/date_time_utils.dart';
import 'package:da_crust_app/features/cart/state/cart_manager.dart'; 
import 'package:da_crust_app/features/cart/utils/checkout_validator.dart';
import 'package:da_crust_app/features/payments/services/payment_handler.dart';

class CheckoutService {

  static String _generateShortId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rnd = Random();
    return String.fromCharCodes(Iterable.generate(
      5, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))
    ));
  }
  
  static Future<Map<String, String?>> startCheckoutFlow({
    String? currentOrderId, 
    required String firstName,
    required String lastName,
    required String email,
    required String phoneRaw,
    required NzPaymentMethod paymentMethod,
    required double finalTotal,
    required String orderNote,
    required bool wantsSms,
  }) async {
    
    // 1. Validate
    final validationError = CheckoutValidator.validate(
      firstName: firstName,
      lastName: lastName,
      email: email,
      phoneRaw: phoneRaw,
    );
    if (validationError != null) return {'error': validationError, 'orderId': null};

    final String orderId = currentOrderId ?? "ORD-${_generateShortId()}";
    final scheduledTime = DateTimeUtils.getActualDateTime();
    final int milliseconds = scheduledTime.millisecondsSinceEpoch;

    try {
      // Step B: Snapshot the cart
      final cartItemsMap = CartManager.instance.items.map((cartItem) => {
        'menuId': cartItem.item.menuId,
        'name': cartItem.item.name,
        'selectedSize': cartItem.selectedSize,
        'selectedSpice': cartItem.selectedSpice, 
        'imagePath': cartItem.item.imagePath,
        'quantity': cartItem.quantity,
        'unitPriceAtAddition': cartItem.unitPriceAtAddition,
        'totalPrice': cartItem.unitPriceAtAddition * cartItem.quantity,
      }).toList();

      final cleanedPhone = phoneRaw.replaceAll(' ', '');
      
      // Step C: Upsert to Firestore
      await FirebaseFirestore.instance.collection('orders').doc(orderId).set({
        'orderId': orderId,
        'status': 'PENDING',
        'orderType': 'Pickup', 
        'customerName': '$firstName $lastName'.trim(),
        'customerEmail': email,
        'customerPhone': cleanedPhone,
        'totalAmount': finalTotal,
        'orderNote': orderNote,
        'wantsSms': wantsSms,
        'scheduledTime': DateTimeUtils.formatDateTime(scheduledTime),
        'scheduledTimeEpoch': milliseconds, 
        'items': cartItemsMap,
        'intendedPaymentMethod': paymentMethod.name,
        'updatedAt': FieldValue.serverTimestamp(),
        if (currentOrderId == null) 'createdAt': FieldValue.serverTimestamp(), 
      }, SetOptions(merge: true));

      //Step D: Hand over to the Payment Handler
      await PaymentHandler.process(
        method: paymentMethod,
        amount: finalTotal,
        orderId: orderId,
        scheduledTime: milliseconds,
        customerPhone: cleanedPhone,
      );
      
      await CartManager.instance.setPendingOrderId(orderId);
      return {'error': null, 'orderId': orderId}; 
      
    } catch (e) {
      return {
        'error': "Checkout failed: ${e.toString()}", 
        'orderId': orderId 
      };
    }
  }
}