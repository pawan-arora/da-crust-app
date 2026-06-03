import 'package:da_crust_app/data/model/menu_item.dart';
import 'package:da_crust_app/features/menu/widgets/menu_card.dart';
import 'package:flutter/material.dart';

class MenuGrid extends StatelessWidget {
  final List<MenuItem> items;

  const MenuGrid({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(40.0),
        child: Center(
          child: Text(
            "No items found in this category.",
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      // 🌟 Replaced Wrap with a responsive, lazy-loading GridView
      child: GridView.builder(
        shrinkWrap: true, // Allows it to sit inside your CustomScrollView
        physics: const NeverScrollableScrollPhysics(), // Passes scrolling up to the CustomScrollView
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 250, // 👈 Adjust this to match your desired max card width
          mainAxisSpacing: 24.0,
          crossAxisSpacing: 16.0,
          childAspectRatio: 0.75, // 👈 Adjust this ratio to fit your card's height (Width / Height)
          mainAxisExtent: 400,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          return MenuCard(item: items[index]);
        },
      ),
    );
  }
}