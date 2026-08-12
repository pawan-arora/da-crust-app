import 'package:da_crust_app/core/widgets/modern_carousel.dart';
import 'package:da_crust_app/data/model/menu_item.dart';
import 'package:da_crust_app/features/menu/widgets/menu_card.dart';
import 'package:flutter/material.dart';

class ModernMenuRow extends StatelessWidget {
  final List<MenuItem> items;

  const ModernMenuRow({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    // 🌟 1. Grab screen width to dynamically size the cards
    final isMobile = MediaQuery.of(context).size.width < 600;

    // 🌟 2. If mobile, shrink the width to 180 to perfectly match the GridView math!
    final double cardWidth = isMobile ? 180.0 : 220.0;

    return ModernCarousel(
      height: isMobile ? 340 : 420,
      scrollAmount: 500,
      items: items.map((item) {
        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: cardWidth, // 👇 Use the dynamic width
            child: MenuCard(item: item),
          ),
        );
      }).toList(),
    );
  }
}
