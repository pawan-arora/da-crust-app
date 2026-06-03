import 'package:da_crust_app/data/model/menu_item.dart';
import 'package:da_crust_app/features/cart/state/cart_manager.dart';
import 'package:da_crust_app/features/menu/widgets/base_customization_dialog.dart';
import 'package:flutter/material.dart';

class SizeSelectionDialog extends StatefulWidget {
  final MenuItem item;
  const SizeSelectionDialog({super.key, required this.item});

  @override
  State<SizeSelectionDialog> createState() => _SizeSelectionDialogState();
}

class _SizeSelectionDialogState extends State<SizeSelectionDialog> {
  final Map<String, int> _sizeQuantities = {};

  @override
  void initState() {
    super.initState();
    for (var size in widget.item.sizes) {
      _sizeQuantities[size.name] = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    int totalSelected = _sizeQuantities.values.fold(0, (sum, val) => sum + val);

    return BaseCustomizationDialog(
      item: widget.item,
      content: [
        const Text("Select Sizes", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 12),
        ...widget.item.sizes.map((sizeOption) {
          int currentQty = _sizeQuantities[sizeOption.name]!;
          return Padding(
            key: ValueKey("size_${sizeOption.name}"), // Unique key for safety
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(sizeOption.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text('\$${sizeOption.price.toStringAsFixed(2)}', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
                  ],
                ),
                DialogQuantityStepper(
                  quantity: currentQty,
                  onDecrement: currentQty > 0 ? () => setState(() => _sizeQuantities[sizeOption.name] = currentQty - 1) : null,
                  onIncrement: () => setState(() => _sizeQuantities[sizeOption.name] = currentQty + 1),
                ),
              ],
            ),
          );
        }),
      ],
      bottomButton: SizedBox(
        width: double.infinity, height: 48,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: totalSelected > 0 ? Theme.of(context).primaryColor : Colors.grey.shade400,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: totalSelected > 0 ? () {
            _sizeQuantities.forEach((sizeName, qty) {
              if (qty > 0) CartManager.instance.addItem(widget.item, quantity: qty, size: sizeName);
            });
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$totalSelected item(s) added!"), backgroundColor: Colors.green.shade600));
            Navigator.pop(context);
          } : null,
          child: Text("Add $totalSelected to Cart", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}