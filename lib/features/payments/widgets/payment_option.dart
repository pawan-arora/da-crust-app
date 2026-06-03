import 'package:da_crust_app/features/payments/services/payment_handler.dart';
import 'package:flutter/material.dart';

class PaymentOption extends StatelessWidget {
  const PaymentOption({
    super.key,
    required this.selectedPayment,
    required this.onPaymentChanged,
    required this.context,
    required this.method,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final NzPaymentMethod selectedPayment;
  final ValueChanged<NzPaymentMethod> onPaymentChanged;
  final BuildContext context;
  final NzPaymentMethod method;
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    bool isSelected = selectedPayment == method;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: InkWell(
        onTap: () => onPaymentChanged(method), // Calls the parent screen to update state!
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).primaryColor.withAlpha(10) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? Theme.of(context).primaryColor.withAlpha(80) : Colors.transparent)
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_off, color: isSelected ? Theme.of(context).primaryColor : Colors.grey),
              const SizedBox(width: 12),
              Icon(icon, color: Colors.black87),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.3)),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}