import 'package:da_crust_app/data/model/menu_item.dart';
import 'package:da_crust_app/features/menu/widgets/modern_menu_row.dart';
import 'package:flutter/material.dart';

class BestsellersSection extends StatelessWidget {
  final List<MenuItem> items;

  const BestsellersSection({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          // --- 🌟 THE FIX: Replaced Emoji with a Native Icon Row ---
          child: Row(
            children: [
              Icon(
                Icons.star_rounded, // A softer, modern star icon
                color: Theme.of(context).primaryColor, // Pops with your brand color!
                size: 26,
              ),
              const SizedBox(width: 8),
              Text(
                "Recommended",
                // 🌟 THE FIX: Ties into your global theme instead of hardcoding
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
        
        ModernMenuRow(items: items),
      ],
    );
  }
}