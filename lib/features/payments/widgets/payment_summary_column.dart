import 'package:da_crust_app/features/cart/state/cart_manager.dart';
import 'package:da_crust_app/features/menu/widgets/item_quantity_stepper.dart';
import 'package:da_crust_app/features/menu/widgets/safe_menu_image.dart';
import 'package:da_crust_app/features/payments/services/payment_handler.dart';
import 'package:da_crust_app/features/payments/widgets/payment_option.dart';
import 'package:flutter/material.dart';

class PaymentSummaryColumn extends StatelessWidget {
  final NzPaymentMethod selectedPayment;
  final ValueChanged<NzPaymentMethod> onPaymentChanged;
  final double subtotal;
  final double surcharge;
  final double finalTotal;
  final bool isProcessing;
  final double taxRate;
  final VoidCallback onCheckoutPressed;

  const PaymentSummaryColumn({
    super.key,
    required this.selectedPayment,
    required this.onPaymentChanged,
    required this.subtotal,
    required this.surcharge,
    required this.finalTotal,
    required this.isProcessing,
    required this.onCheckoutPressed,
    required this.taxRate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Order summary",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          // --- CART ITEMS ---
          ...CartManager.instance.items.map((cartItem) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SafeMenuImage(
                        imagePath: cartItem.item.imagePath,
                        height: 60,
                        width: 60,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cartItem.item.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        if (cartItem.selectedSize != null)
                          Text(
                            "Size: ${cartItem.selectedSize}",
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        // 🌟 THE FIX: Show the spice level in the Order Summary!
                        if (cartItem.selectedSpice != null)
                          Text(
                            "Spice: ${cartItem.selectedSpice}",
                            style: TextStyle(
                              color: Colors.red.shade400,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            SizedBox(
                              width: 100,
                              child: ItemQuantityStepper(
                                quantity: cartItem.quantity,
                                onIncrement: () =>
                                    CartManager.instance.updateQuantity(
                                      cartItem,
                                      cartItem.quantity + 1,
                                    ),
                                onDecrement: () {
                                  if (cartItem.quantity > 1) {
                                    CartManager.instance.updateQuantity(
                                      cartItem,
                                      cartItem.quantity - 1,
                                    );
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () =>
                                  CartManager.instance.removeItem(cartItem),
                              borderRadius: BorderRadius.circular(6),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Icon(
                                  Icons.delete_outline,
                                  size: 20,
                                  color: Colors.red.shade400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Text(
                    "\$${cartItem.totalPrice.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Divider(),
          ),

          // --- MATH & TOTALS ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Subtotal", style: TextStyle(fontSize: 15)),
              Text(
                "\$${subtotal.toStringAsFixed(2)}",
                style: const TextStyle(fontSize: 15),
              ),
            ],
          ),

          if (surcharge > 0) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Card Surcharge (2%)",
                  style: TextStyle(fontSize: 14, color: Colors.red.shade700),
                ),
                Text(
                  "\$${surcharge.toStringAsFixed(2)}",
                  style: TextStyle(fontSize: 14, color: Colors.red.shade700),
                ),
              ],
            ),
          ],

          const Divider(height: 32),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Total to pay",
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Text(
                "\$${finalTotal.toStringAsFixed(2)}",
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "All prices are in NZD and inclusive of ${taxRate.toStringAsFixed(2)}% GST.",
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),

          const SizedBox(height: 32),
          const Text(
            "Choose Payment Method",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),

          // --- PAYMENT OPTIONS ---
          PaymentOption(
            selectedPayment: selectedPayment,
            onPaymentChanged: onPaymentChanged,
            context: context,
            method: NzPaymentMethod.card,
            icon: Icons.credit_card,
            title: "Credit / Debit Card",
            subtitle: "Visa, Mastercard, Amex (2% surcharge)",
          ),
          PaymentOption(
            selectedPayment: selectedPayment,
            onPaymentChanged: onPaymentChanged,
            context: context,
            method: NzPaymentMethod.eftpos,
            icon: Icons.phone_iphone,
            title: "Online EFTPOS",
            subtitle: "Pay directly from bank app. No surcharge.",
          ),
          PaymentOption(
            selectedPayment: selectedPayment,
            onPaymentChanged: onPaymentChanged,
            context: context,
            method: NzPaymentMethod.afterpay,
            icon: Icons.money_off,
            title: "Afterpay",
            subtitle: "Buy now, pay later.",
          ),

          if (selectedPayment == NzPaymentMethod.afterpay)
            Padding(
              padding: const EdgeInsets.only(left: 44.0, top: 4.0),
              child: Text(
                "or 4 interest-free payments of \$${(finalTotal / 4).toStringAsFixed(2)}",
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.teal.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: isProcessing ? null : onCheckoutPressed,
              child: isProcessing
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      "Pay \$${finalTotal.toStringAsFixed(2)}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
