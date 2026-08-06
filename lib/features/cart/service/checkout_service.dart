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
    return String.fromCharCodes(
      Iterable.generate(5, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))),
    );
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
    if (validationError != null) {
      return {'error': validationError, 'orderId': null};
    }

    // 2. Reuse existing pending order if available
    //    Priority: argument → CartManager → generate new
    final existingId = currentOrderId ?? CartManager.instance.currentOrderId;
    final bool isNewOrder = existingId == null || existingId.isEmpty;
    final String orderId = isNewOrder ? "ORD-${_generateShortId()}" : existingId;

    // Prefer the time the user selected in the cart
    final scheduledTime =
        CartManager.instance.scheduledTime ?? DateTimeUtils.getActualDateTime();
    final int milliseconds = scheduledTime.millisecondsSinceEpoch;

    try {
      // 3. Snapshot the cart
      final cartItemsMap = CartManager.instance.items.map((cartItem) {
        return {
          'menuId': cartItem.item.menuId,
          'name': cartItem.item.name,
          'selectedSize': cartItem.selectedSize,
          'selectedSpice': cartItem.selectedSpice,
          'imagePath': cartItem.item.imagePath,
          'quantity': cartItem.quantity,
          'unitPriceAtAddition': cartItem.unitPriceAtAddition,
          'totalPrice': cartItem.unitPriceAtAddition * cartItem.quantity,
        };
      }).toList();

      final cleanedPhone = phoneRaw.replaceAll(' ', '');

      // 4. Upsert order (create once, update on retries)
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
        if (isNewOrder) 'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 5. Save pending order ID BEFORE redirecting to payment
      //    (redirect can unload the page, so this must happen first)
      await CartManager.instance.setPendingOrderId(orderId);

      // 6. Hand over to payment gateway
      await PaymentHandler.process(
        method: paymentMethod,
        amount: finalTotal,
        orderId: orderId,
        scheduledTime: milliseconds,
        customerPhone: cleanedPhone,
      );

      return {'error': null, 'orderId': orderId};
    } catch (e) {
      return {
        'error': 'Checkout failed: ${e.toString()}',
        'orderId': orderId,
      };
    }
  }
}