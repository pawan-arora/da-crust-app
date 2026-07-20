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

  bool wantsSms = true;

  CheckoutViewModel()
      : noteController = TextEditingController(
          text: CartManager.instance.orderNote,
        ) {
    _prefillCustomerDetails();
    _loadLocationData();

    // Listen to cart changes
    CartManager.instance.addListener(notifyListeners);

    // Auto-save customer details when user types
    firstNameController.addListener(_saveCustomerDetails);
    lastNameController.addListener(_saveCustomerDetails);
    emailController.addListener(_saveCustomerDetails);
    phoneController.addListener(_saveCustomerDetails);
  }

  /// Prefill form from CartManager (survives browser refresh)
  void _prefillCustomerDetails() {
    final cart = CartManager.instance;

    firstNameController.text = cart.firstName;
    lastNameController.text = cart.lastName;
    emailController.text = cart.email;
    phoneController.text = cart.phone;
    wantsSms = cart.wantsSms;
  }

  /// Save current form values into CartManager
  void _saveCustomerDetails() {
    CartManager.instance.updateCustomerDetails(
      firstName: firstNameController.text.trim(),
      lastName: lastNameController.text.trim(),
      email: emailController.text.trim(),
      phone: phoneController.text.trim(),
      wantsSms: wantsSms,
    );
  }

  @override
  void dispose() {
    CartManager.instance.removeListener(notifyListeners);

    firstNameController.removeListener(_saveCustomerDetails);
    lastNameController.removeListener(_saveCustomerDetails);
    emailController.removeListener(_saveCustomerDetails);
    phoneController.removeListener(_saveCustomerDetails);

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
      wantsSms = data['wantsSms'] ?? true; // Default to true if not specified
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

  void toggleSmsPreference(bool value) {
    wantsSms = value;
    _saveCustomerDetails(); // also save SMS preference
    notifyListeners();
  }

  // --- Submission ---
  Future<String?> submitOrder() async {
    isProcessing = true;
    notifyListeners();

    // Make sure latest values are saved before submitting
    _saveCustomerDetails();

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