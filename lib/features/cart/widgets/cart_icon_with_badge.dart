import 'package:da_crust_app/features/cart/screens/cart_side_sheet.dart';
import 'package:da_crust_app/features/cart/state/cart_manager.dart';
import 'package:flutter/material.dart';

class CartIconWithBadge extends StatelessWidget {
  const CartIconWithBadge({super.key});

  @override
  Widget build(BuildContext context) {
    // ListenableBuilder automatically rebuilds this icon when the cart changes!
    return ListenableBuilder(
      listenable: CartManager.instance,
      builder: (context, _) {
        final count = CartManager.instance.totalItemCount;
        
        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.shopping_cart, size: 28),
              onPressed: () {
                // Open the shiny new Cart Screen
                CartSideSheet.show(context);
              },
            ),
            if (count > 0)
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        );
      }
    );
  }
}