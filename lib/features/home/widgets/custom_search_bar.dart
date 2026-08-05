import 'package:flutter/material.dart';

class CustomSearchBar extends StatefulWidget {
  final ValueChanged<String> onChanged;
  final String? initialValue;

  const CustomSearchBar({
    super.key,
    required this.onChanged,
    this.initialValue,
  });

  @override
  State<CustomSearchBar> createState() => CustomSearchBarState();
}

class CustomSearchBarState extends State<CustomSearchBar> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void clear() {
    _controller.clear();
    widget.onChanged('');
  }

  @override
  Widget build(BuildContext context) {
    // 🌟 Determine if we are on mobile to dynamically adjust constraints
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Padding(
      // 👇 FIX 1: Remove the hardcoded left/right padding on mobile to prevent double-padding
      padding: EdgeInsets.fromLTRB(
        isMobile ? 0 : 20,
        isMobile ? 0 : 16,
        isMobile ? 0 : 20,
        8,
      ),
      child: Row(
        children: [
          // --- 1. THE SEARCH BAR ---
          Expanded(
            child: SizedBox(
              height: 42,
              child: TextField(
                onChanged: widget.onChanged,
                controller: _controller,
                maxLength: 50,
                decoration: InputDecoration(
                  // 👇 FIX 2: Slightly shorter hint text on mobile
                  hintText: isMobile ? "Search..." : "I'm looking for...",
                  hintStyle: TextStyle(fontSize: isMobile ? 14 : 16),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Colors.grey,
                    size: 20,
                  ),
                  counterText: "",
                ),
              ),
            ),
          ),

          // 👇 FIX 3: Shrink the huge 20px gap down to 10px on mobile
          SizedBox(width: isMobile ? 10 : 20),

          // --- 2. PICK UP ONLY BADGE ---
          Container(
            height: 42,
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary.withAlpha(20),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Theme.of(context).colorScheme.secondary.withAlpha(51),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.shopping_bag_outlined,
                  size: isMobile ? 14 : 16,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                SizedBox(width: isMobile ? 4 : 6),
                Text(
                  // 👇 FIX 4: Use a punchier text on small screens to save horizontal space
                  isMobile ? "Pick Up" : "Pick Up Only",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 12 : 12,
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