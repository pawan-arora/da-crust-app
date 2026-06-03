import 'package:da_crust_app/data/model/menu_item.dart';
import 'package:da_crust_app/features/cart/state/cart_manager.dart';
import 'package:da_crust_app/features/menu/widgets/base_customization_dialog.dart';
import 'package:flutter/material.dart';

class SpiceSelectionDialog extends StatefulWidget {
  final MenuItem item;
  const SpiceSelectionDialog({super.key, required this.item});

  @override
  State<SpiceSelectionDialog> createState() => _SpiceSelectionDialogState();
}

class _SpiceSelectionDialogState extends State<SpiceSelectionDialog> {
  String? _selectedSpice; 
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    // 🌟 FIX: Default to "Mild" if available, otherwise pick the first option
    if (widget.item.spiceLevels.contains("Mild")) {
      _selectedSpice = "Mild";
    } else if (widget.item.spiceLevels.isNotEmpty) {
      _selectedSpice = widget.item.spiceLevels.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    bool canAdd = _selectedSpice != null;

    return BaseCustomizationDialog(
      item: widget.item,
      content: [
        const Text("Choose Spice Level *", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 8),
        
        ...widget.item.spiceLevels.map((spice) => RadioListTile<String>(
          key: ValueKey("spice_$spice"),
          title: Text(spice, style: const TextStyle(fontSize: 15)),
          value: spice,
          groupValue: _selectedSpice,
          onChanged: (val) {
            if (val != null) {
              setState(() => _selectedSpice = val);
            }
          },
          activeColor: Theme.of(context).primaryColor,
          contentPadding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
        )),
        
        const SizedBox(height: 16),
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
            backgroundColor: canAdd ? Theme.of(context).primaryColor : Colors.grey.shade400,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: canAdd ? () {
            CartManager.instance.addItem(widget.item, quantity: _quantity, spice: _selectedSpice);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$_quantity item(s) added!"), backgroundColor: Colors.green.shade600));
            Navigator.pop(context);
          } : null,
          child: Text("Add $_quantity to Cart - \$${(widget.item.displayPrice * _quantity).toStringAsFixed(2)}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}