import 'package:da_crust_app/data/model/menu_item.dart';
import 'package:da_crust_app/features/menu/widgets/modern_menu_row.dart';
import 'package:flutter/material.dart';

class MenuSection extends StatelessWidget {
  final Map<String, List<MenuItem>> grouped;
  final Function(String) onCategoryTap;

  const MenuSection({
    super.key,
    required this.grouped,
    required this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: grouped.entries.map((entry) {
        
        // Safety check: Don't render a category if it's empty
        if (entry.value.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(bottom: 24.0), 
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- CATEGORY HEADER ---
              InkWell(
                onTap: () => onCategoryTap(entry.key),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        entry.key,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 18,
                        color: Theme.of(context).primaryColor,
                      ),
                    ],
                  ),
                ),
              ),
              
              // --- THE MODERN CAROUSEL ---
              ModernMenuRow(items: entry.value),
              
            ],
          ),
        );
      }).toList(),
    );
  }
}