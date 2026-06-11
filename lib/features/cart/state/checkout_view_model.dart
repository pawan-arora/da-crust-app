import 'package:flutter/material.dart';
import 'package:da_crust_app/app_config.dart';
import 'package:da_crust_app/features/cart/service/checkout_service.dart';
import 'package:da_crust_app/features/cart/state/cart_manager.dart';
import 'package:da_crust_app/features/home/services/restaurant_service.dart';
import 'package:da_crust_app/features/payments/services/payment_handler.dart';

class CheckoutViewModel extends ChangeNotifier {
  // --- UI State ---
  bool isProcessing = false;
  String? currentOrderId;
  NzPaymentMethod selectedPayment = NzPaymentMethod.card;

  // --- Restaurant Data State ---
  String restaurantName = "Da Crust Pizzeria";
  String pickupAddress = "Loading address...";

  // --- Form Controllers ---
  final TextEditingController noteController;
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  CheckoutViewModel()
    : noteController = TextEditingController(
        text: CartManager.instance.orderNote,
      ) {
    _loadLocationData();
    // Re-calculate totals if cart changes while on this screen
    CartManager.instance.addListener(notifyListeners);
  }

  @override
  void dispose() {
    CartManager.instance.removeListener(notifyListeners);
    noteController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  // --- Methods ---
  void updatePaymentMethod(NzPaymentMethod method) {
    selectedPayment = method;
    notifyListeners();
  }

  Future<void> _loadLocationData() async {
    final data = await RestaurantService.instance.fetchRestaurantData();
    if (data != null) {
      restaurantName = data['name'] ?? "Da Crust Pizzeria & Indian Takeaways";
      final addressMap = data['address'] as Map<String, dynamic>? ?? {};
      final street = addressMap['street'] ?? "20 Diana Street";
      final city = addressMap['city'] ?? "Lumsden";
      pickupAddress = "$street, $city";
      notifyListeners();
    }
  }

  // --- Business Logic Math ---
  double get subtotal => CartManager.instance.totalCartPrice;

  double get includedTax =>
      subtotal - (subtotal / (1 + AppConfig.instance.taxRate));

  double get currentSurcharge => selectedPayment == NzPaymentMethod.card
      ? (subtotal * AppConfig.instance.cardSurchargeRate)
      : 0.0;

  double get finalTotal =>
      double.parse((subtotal + currentSurcharge).toStringAsFixed(2));

  bool wantsSms = false;

  void toggleSmsPreference(bool value) {
    wantsSms = value;
    notifyListeners();
  }

  // --- Submission ---
  Future<String?> submitOrder() async {
    isProcessing = true;
    notifyListeners();

    // The CartManager now holds the time, we don't need a getter here!
    final result = await CheckoutService.startCheckoutFlow(
      currentOrderId: currentOrderId,
      firstName: firstNameController.text.trim(),
      lastName: lastNameController.text.trim(),
      email: emailController.text.trim(),
      phoneRaw: phoneController.text.trim(),
      paymentMethod: selectedPayment,
      finalTotal: finalTotal,
      orderNote: noteController.text,
      wantsSms: wantsSms,
    );

    isProcessing = false;
    notifyListeners();

    if (result['orderId'] != null) {
      currentOrderId = result['orderId'];
    }

    return result['error']; // Returns null on success
  }
}
