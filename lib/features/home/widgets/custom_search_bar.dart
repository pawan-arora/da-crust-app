import 'package:flutter/material.dart';

class CustomSearchBar extends StatelessWidget {
  final ValueChanged<String> onChanged;

  const CustomSearchBar({super.key, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          // --- 1. THE SEARCH BAR ---
          Expanded(
            child: SizedBox(
              height: 42, 
              child: TextField(
                onChanged: onChanged, 
                // Adds a maximum limit of 50 characters
                maxLength: 50, 
                decoration: const InputDecoration(
                  hintText: "I'm looking for...",
                  prefixIcon: Icon(Icons.search, color: Colors.grey, size: 20),
                  
                  // Hides the "0/50" counter text so it doesn't break your 42px height!
                  counterText: "", 
                  
                  // 🌟 NOTICE: All hardcoded borders and colors are GONE!
                  // It now automatically inherits everything from your AppTheme.
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 20), 
          
          // --- 2. PICK UP ONLY BADGE ---
          Container(
            height: 42, 
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              // Uses withAlpha (0-255 scale) instead of the deprecated withOpacity
              color: Theme.of(context).colorScheme.secondary.withAlpha(20),
              borderRadius: BorderRadius.circular(30), 
              border: Border.all(color: Theme.of(context).colorScheme.secondary.withAlpha(51)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.shopping_bag_outlined, 
                  size: 16, 
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(width: 6),
                Text(
                  "Pick Up Only",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12, 
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}