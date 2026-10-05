import 'package:da_crust_app/data/model/cart_item.dart';
import 'package:da_crust_app/features/cart/state/cart_manager.dart';
import 'package:da_crust_app/features/menu/widgets/base_customization_dialog.dart';
import 'package:flutter/material.dart';

/// Lets the customer change the size and/or spice level of an item that is
/// already in the cart, instead of deleting it and adding it again.
class EditCartItemDialog extends StatefulWidget {
  final CartItem cartItem;
  const EditCartItemDialog({super.key, required this.cartItem});

  /// Only items with a size or spice choice have anything to edit.
  static bool canEdit(CartItem cartItem) =>
      cartItem.item.sizes.isNotEmpty || cartItem.item.spiceLevels.isNotEmpty;

  static Future<void> show(BuildContext context, CartItem cartItem) {
    return showDialog(
      context: context,
      builder: (context) => EditCartItemDialog(cartItem: cartItem),
    );
  }

  @override
  State<EditCartItemDialog> createState() => _EditCartItemDialogState();
}

class _EditCartItemDialogState extends State<EditCartItemDialog> {
  String? _selectedSize;
  String? _selectedSpice;
  late int _quantity;

  @override
  void initState() {
    super.initState();
    final cartItem = widget.cartItem;
    final item = cartItem.item;
    _quantity = cartItem.quantity;

    if (item.sizes.isNotEmpty) {
      final current = cartItem.selectedSize;
      _selectedSize = item.sizes.any((s) => s.name == current)
          ? current
          : item.sizes.first.name;
    }
    if (item.spiceLevels.isNotEmpty) {
      final current = cartItem.selectedSpice;
      _selectedSpice = item.spiceLevels.contains(current)
          ? current
          : item.spiceLevels.first;
    }
  }

  double get _unitPrice {
    final item = widget.cartItem.item;
    if (_selectedSize == widget.cartItem.selectedSize) {
      return widget.cartItem.unitPriceAtAddition;
    }
    if (_selectedSize != null) {
      return item.sizes.firstWhere((s) => s.name == _selectedSize).price;
    }
    return item.price ?? 0.0;
  }

  void _save() {
    CartManager.instance.updateCartItem(
      widget.cartItem,
      size: _selectedSize,
      spice: _selectedSpice,
      quantity: _quantity,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Item updated!"),
        backgroundColor: Colors.green.shade600,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.cartItem.item;
    final primaryColor = Theme.of(context).primaryColor;

    return BaseCustomizationDialog(
      item: item,
      content: [
        if (item.sizes.isNotEmpty) ...[
          const Text("Size", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          RadioGroup<String>(
            groupValue: _selectedSize,
            onChanged: (val) => setState(() => _selectedSize = val),
            child: Column(
              children: item.sizes.map((size) => RadioListTile<String>(
                key: ValueKey("edit_size_${size.name}"),
                title: Text(size.name, style: const TextStyle(fontSize: 15)),
                secondary: Text(
                  '\$${size.price.toStringAsFixed(2)}',
                  style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                ),
                value: size.name,
                activeColor: primaryColor,
                contentPadding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              )).toList(),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (item.spiceLevels.isNotEmpty) ...[
          const Text("Spice Level", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          RadioGroup<String>(
            groupValue: _selectedSpice,
            onChanged: (val) => setState(() => _selectedSpice = val),
            child: Column(
              children: item.spiceLevels.map((spice) => RadioListTile<String>(
                key: ValueKey("edit_spice_$spice"),
                title: Text(spice, style: const TextStyle(fontSize: 15)),
                value: spice,
                activeColor: primaryColor,
                contentPadding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              )).toList(),
            ),
          ),
          const SizedBox(height: 16),
        ],
        const Divider(),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Quantity", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            DialogQuantityStepper(
              quantity: _quantity,
              onDecrement: _quantity > 1 ? () => setState(() => _quantity--) : null,
              onIncrement: () => setState(() => _quantity++),
            ),
          ],
        ),
      ],
      bottomButton: SizedBox(
        width: double.infinity, height: 48,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: _save,
          child: Text(
            "Update Item - \$${(_unitPrice * _quantity).toStringAsFixed(2)}",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
