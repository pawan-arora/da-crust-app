import 'package:da_crust_app/core/constants/app_assets.dart';
import 'package:flutter/material.dart';

/// Footer strip showing the payment options available at checkout.
class PaymentMethodsRow extends StatelessWidget {
  const PaymentMethodsRow({super.key});

  static const double _badgeHeight = 40;
  static const double _logoHeight = 22;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "We accept",
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _logoBadge(AppAssets.paymentVisa, "Visa", logoHeight: 16),
            _logoBadge(AppAssets.paymentMastercard, "Mastercard"),
            _logoBadge(AppAssets.paymentAmex, "American Express", logoHeight: 30),
            _afterpayBadge(),
            _eftposBadge(),
          ],
        ),
      ],
    );
  }

  Widget _badge({required Widget child, Color color = Colors.white}) {
    return Container(
      height: _badgeHeight,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: child,
    );
  }

  Widget _logoBadge(
    String asset,
    String label, {
    double logoHeight = _logoHeight,
  }) {
    return _badge(
      child: Center(
        widthFactor: 1,
        child: Image.asset(asset, height: logoHeight, semanticLabel: label),
      ),
    );
  }

  Widget _afterpayBadge() {
    return _badge(
      color: const Color(0xFFB2FCE4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "afterpay",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
          const SizedBox(width: 4),
          Image.asset(
            AppAssets.paymentAfterpayMark,
            height: _logoHeight,
            excludeFromSemantics: true,
          ),
        ],
      ),
    );
  }

  Widget _eftposBadge() {
    return _badge(
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.phone_iphone, size: 18, color: Colors.black87),
          SizedBox(width: 6),
          Text(
            "Online EFTPOS",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
