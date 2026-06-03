import 'package:da_crust_app/features/cart/state/cart_manager.dart';
import 'package:da_crust_app/features/cart/state/checkout_view_model.dart';
import 'package:da_crust_app/features/cart/widgets/custom_text_field.dart';
import 'package:da_crust_app/features/home/widgets/order_time_selector.dart';
import 'package:da_crust_app/features/payments/widgets/payment_summary_column.dart';
import 'package:flutter/material.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  // 🌟 The only state this screen needs is the ViewModel!
  late final CheckoutViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = CheckoutViewModel();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  void _handleCheckout() async {
    final errorMessage = await _viewModel.submitOrder();

    if (!mounted) return;

    if (errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            errorMessage,
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          "Secure Checkout",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      // 🌟 Listen to the ViewModel to rebuild the UI when math/state changes
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          if (CartManager.instance.items.isEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (Navigator.canPop(context)) Navigator.pop(context);
            });
            return const Center(child: CircularProgressIndicator());
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              bool isDesktop = constraints.maxWidth > 900;

              if (isDesktop) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 40.0),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 6,
                              child: _buildDetailsColumn(context),
                            ),
                            const SizedBox(width: 24),
                            Expanded(flex: 4, child: _buildPaymentSummary()),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              } else {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildDetailsColumn(context),
                      const SizedBox(height: 24),
                      _buildPaymentSummary(),
                    ],
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildPaymentSummary() {
    return PaymentSummaryColumn(
      taxRate: _viewModel.includedTax,
      selectedPayment: _viewModel.selectedPayment,
      onPaymentChanged: _viewModel.updatePaymentMethod,
      subtotal: _viewModel.subtotal,
      surcharge: _viewModel.currentSurcharge,
      finalTotal: _viewModel.finalTotal,
      isProcessing: _viewModel.isProcessing,
      onCheckoutPressed: _handleCheckout,
    );
  }

  Widget _buildDetailsColumn(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPickupDetailsCard(context),
        const SizedBox(height: 32),

        const Text(
          "Special Instructions",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        CustomTextField(
          controller: _viewModel.noteController,
          labelText: "Special Instructions",
          hintText: "E.g. No onions, extra spicy, allergies...",
          isRequired: false,
          minLines: 3,
          maxLines: 5,
          maxLength: 300,
          onChanged: (value) => CartManager.instance.updateOrderNote(value),
        ),

        const SizedBox(height: 32),

        const Text(
          "Your Details",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _viewModel.firstNameController,
                      labelText: "First name",
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextField(
                      controller: _viewModel.lastNameController,
                      labelText: "Last name",
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _viewModel.emailController,
                labelText: "Email address",
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _viewModel.phoneController,
                labelText: "Mobile number",
                hintText: "21 123 4567",
                keyboardType: TextInputType.phone,
                maxLength: 10,
                prefixIcon: const Padding(
                  padding: EdgeInsets.all(14.0),
                  child: Text(
                    "🇳🇿 +64",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text(
                  "Send me an SMS text order update",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                value: _viewModel.wantsSms,
                onChanged: _viewModel.toggleSmsPreference,
                contentPadding: EdgeInsets.zero,

                // 🌟 REPLACES activeColor: Controls the circular knob color
                thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
                  if (states.contains(WidgetState.selected)) {
                    return Theme.of(context).primaryColor; // Color when ON
                  }
                  return Colors.grey.shade400; // Color when OFF
                }),

                // 🌟 (Optional) Controls the pill-shaped background track
                trackColor: WidgetStateProperty.resolveWith<Color>((states) {
                  if (states.contains(WidgetState.selected)) {
                    return Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.4); // Track when ON
                  }
                  return Colors.grey.shade300; // Track when OFF
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPickupDetailsCard(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Pickup Details",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.storefront,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _viewModel.restaurantName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _viewModel.pickupAddress,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      // Using a nested ListenableBuilder here specifically for the time
                      // so we don't repaint the whole form when just the time changes!
                      child: ListenableBuilder(
                        listenable: CartManager.instance,
                        builder: (context, _) {
                          return OrderTimeSelector(
                            scheduledTime: CartManager.instance.scheduledTime,
                            onTimeChanged: (newTime) {
                              CartManager.instance.updateScheduledTime(newTime);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
