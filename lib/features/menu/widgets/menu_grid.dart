import 'package:da_crust_app/data/model/menu_item.dart';
import 'package:da_crust_app/features/menu/widgets/menu_card.dart';
import 'package:flutter/material.dart';

/// Builds the menu grid as slivers instead of one eagerly-built Column, so
/// only the rows actually inside (or near) the viewport are built and have
/// their images decoded. Building every card at once — including ones far
/// off-screen — was firing a burst of simultaneous image decodes whenever
/// the user scrolled quickly, which on Flutter Web overwhelms the decoder
/// and causes ImageCodecException ("Failed to create image from
/// Image.decode") on otherwise-valid images.
///
/// Call [buildSlivers] from inside a CustomScrollView's `slivers` list
/// instead of placing MenuGrid as a regular child widget.
class MenuGrid {
  MenuGrid._();

  static List<Widget> buildSlivers(
    BuildContext context, {
    required List<MenuItem> items,
  }) {
    if (items.isEmpty) {
      return const [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(40.0),
            child: Center(
              child: Text(
                "No items found in this category.",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
          ),
        ),
      ];
    }

    final isMobile = MediaQuery.of(context).size.width < 600;
    const minCardWidth = 150.0;
    const maxCardWidth = 250.0;
    const spacing = 16.0;
    const runSpacing = 24.0;
    const horizontalPadding = 16.0;

    return [
      SliverPadding(
        padding: const EdgeInsets.all(horizontalPadding),
        sliver: SliverLayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.crossAxisExtent;

            // 🌟 Widest column count that still keeps each card between
            // minCardWidth and maxCardWidth. Cards then stretch evenly to
            // fill the row (never collapses to 1 column just because
            // maxCardWidth doesn't divide evenly into the screen).
            final widestFit =
                ((availableWidth + spacing) / (minCardWidth + spacing))
                    .floor()
                    .clamp(1, 999);
            final narrowestFit =
                ((availableWidth + spacing) / (maxCardWidth + spacing))
                    .floor();
            final desiredColumns = isMobile ? 2 : narrowestFit;
            // 🌟 Column count is based only on how many cards fit the screen
            // width — NOT on how many items exist. Otherwise a category with
            // just 1-2 items would shrink to fewer columns and each card
            // would stretch to fill the whole row (way past maxCardWidth).
            final columns = desiredColumns.clamp(1, widestFit);

            final cardWidth =
                (availableWidth - spacing * (columns - 1)) / columns;

            final rowCount = (items.length / columns).ceil();

            return SliverList.separated(
              itemCount: rowCount,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: runSpacing),
              itemBuilder: (context, rowIndex) {
                final start = rowIndex * columns;
                final rowItems = items
                    .skip(start)
                    .take(columns)
                    .toList();

                // 🌟 Cards are grouped into rows and wrapped in
                // IntrinsicHeight so every card in a row matches the
                // tallest card's real content height instead of a guessed
                // fixed height (a uniform grid can't do this per-row).
                return IntrinsicHeight(
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
                );
              },
            );
          },
        ),
      ),
    ];
  }
}
