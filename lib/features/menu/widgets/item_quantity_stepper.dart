import 'package:flutter/material.dart';

class ItemQuantityStepper extends StatelessWidget {
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const ItemQuantityStepper({
    super.key,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).primaryColor, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: InkWell(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(10)),
              onTap: onDecrement,
              child: Icon(Icons.remove, size: 18, color: Theme.of(context).primaryColor),
            ),
          ),
          Container(
            width: 36,
            alignment: Alignment.center,
            color: Theme.of(context).primaryColor.withAlpha(20),
            child: Text(
              '$quantity',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              borderRadius: const BorderRadius.horizontal(right: Radius.circular(10)),
              onTap: onIncrement,
              child: Icon(Icons.add, size: 18, color: Theme.of(context).primaryColor),
            ),
          ),
        ],
      ),
    );
  }
}