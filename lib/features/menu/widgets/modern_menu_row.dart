import 'package:da_crust_app/core/widgets/modern_carousel.dart';
import 'package:da_crust_app/data/model/menu_item.dart';
import 'package:da_crust_app/features/menu/widgets/menu_card.dart';
import 'package:flutter/material.dart';

class ModernMenuRow extends StatelessWidget {
  final List<MenuItem> items;

  const ModernMenuRow({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    // 🌟 Pass the mapped MenuCards into the generic carousel
    return ModernCarousel(
      height: 420,
      scrollAmount: 500, // Menus scroll further per click than reviews
      items: items.map((item) {
        return SizedBox(
          width: 220, 
          child: MenuCard(item: item),
        );
      }).toList(),
    );
  }
}