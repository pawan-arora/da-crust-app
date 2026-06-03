import 'package:da_crust_app/data/model/menu_item.dart';
import 'package:da_crust_app/features/menu/widgets/safe_menu_image.dart';
import 'package:flutter/material.dart';

class MenuCardImageHeader extends StatelessWidget {
  final MenuItem item;
  
  // 🌟 1. originalPrice parameter removed; we use item.originalPrice now.

  const MenuCardImageHeader({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    // 🌟 2. Updated discount logic to check the boolean flag and ensure the original price is valid
    bool hasDiscount = item.isDiscounted && 
                       item.originalPrice != null && 
                       item.originalPrice! > item.displayPrice;
                       
    // 🌟 3. Calculate percentage based on the model's new properties
    int discountPercent = hasDiscount
        ? (((item.originalPrice! - item.displayPrice) / item.originalPrice!) * 100).round()
        : 0;

    return SizedBox(
      height: 140,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          SafeMenuImage(imagePath: item.imagePath),
          if (hasDiscount)
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  "$discountPercent% OFF",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}