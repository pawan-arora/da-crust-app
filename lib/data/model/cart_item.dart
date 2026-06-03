import 'package:da_crust_app/data/model/menu_item.dart';

class CartItem {
  final MenuItem item;
  int quantity;
  final String? selectedSize;
  final String? selectedSpice; // 🌟 1. Added spice field
  final double unitPriceAtAddition;

  CartItem({
    required this.item,
    required this.quantity,
    this.selectedSize,
    this.selectedSpice, // 🌟 2. Added to constructor
    required this.unitPriceAtAddition,
  });

  double get totalPrice => unitPriceAtAddition * quantity;

  // 🌟 3. Include spice when saving to memory
  Map<String, dynamic> toMap() {
    return {
      'item': item.toMap(),
      'quantity': quantity,
      'selectedSize': selectedSize,
      'selectedSpice': selectedSpice,
      'unitPriceAtAddition': unitPriceAtAddition,
    };
  }

  // 🌟 4. Read spice when loading from memory
  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      item: MenuItem.fromMap(
        Map<String, dynamic>.from(map['item']),
        map['item']['category'] ?? 'Unknown',
      ),
      quantity: map['quantity']?.toInt() ?? 1,
      selectedSize: map['selectedSize']?.toString(),
      selectedSpice: map['selectedSpice']?.toString(),
      unitPriceAtAddition: (map['unitPriceAtAddition'] ?? 0.0).toDouble(),
    );
  }
}