import 'package:flutter/material.dart';

class CategoryChips extends StatelessWidget {
  final List<String> categories;
  final String selected;
  final Function(String) onSelected;

  const CategoryChips({
    super.key,
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 65, // Slightly taller to accommodate the drop shadow
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(), // Modern bouncy scrolling
        padding: const EdgeInsets.symmetric(horizontal: 16), // Outer edge padding
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = selected == cat;

          return Padding(
            padding: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
            child: GestureDetector(
              onTap: () => onSelected(cat),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.deepOrange : Colors.white,
                  borderRadius: BorderRadius.circular(30), // Fully rounded pill shape
                  border: Border.all(
                    color: isSelected ? Colors.deepOrange : Colors.grey.shade300,
                    width: 1.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.deepOrange.withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 4), // Pushes the shadow down slightly
                          )
                        ]
                      : [], // Removes shadow when inactive
                ),
                child: Text(
                  cat,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    fontSize: 15,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}