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

    final isMobile = MediaQuery.of(context).size.width < 600;
    const minCardWidth = 150.0;
    const maxCardWidth = 250.0;
    const spacing = 16.0;
    const runSpacing = 24.0;
    const horizontalPadding = 16.0;

    return Padding(
      padding: const EdgeInsets.all(horizontalPadding),
      // 🌟 Cards are grouped into rows and wrapped in IntrinsicHeight so every
      // card in a row matches the tallest card's real content height instead
      // of a guessed fixed height (GridView can't do this per-row).
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = constraints.maxWidth;

          // 🌟 Widest column count that still keeps each card between
          // minCardWidth and maxCardWidth. Cards then stretch evenly to
          // fill the row (never collapses to 1 column just because
          // maxCardWidth doesn't divide evenly into the screen).
          final widestFit = ((availableWidth + spacing) / (minCardWidth + spacing))
              .floor()
              .clamp(1, 999);
          final narrowestFit =
              ((availableWidth + spacing) / (maxCardWidth + spacing)).floor();
          final desiredColumns = isMobile ? 2 : narrowestFit;
          // 🌟 Column count is based only on how many cards fit the screen
          // width — NOT on how many items exist. Otherwise a category with
          // just 1-2 items would shrink to fewer columns and each card
          // would stretch to fill the whole row (way past maxCardWidth).
          final columns = desiredColumns.clamp(1, widestFit);

          final cardWidth =
              (availableWidth - spacing * (columns - 1)) / columns;

          final rows = <Widget>[];
          for (var i = 0; i < items.length; i += columns) {
            final rowItems = items.skip(i).take(columns).toList();
            rows.add(
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var j = 0; j < rowItems.length; j++) ...[
                      if (j > 0) const SizedBox(width: spacing),
                      SizedBox(
                        width: cardWidth,
                        child: MenuCard(
                          key: ValueKey(rowItems[j].menuId),
                          item: rowItems[j],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0) const SizedBox(height: runSpacing),
                rows[i],
              ],
            ],
          );
        },
      ),
    );
  }
}
