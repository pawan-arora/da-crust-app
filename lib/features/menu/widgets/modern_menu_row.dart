import 'package:da_crust_app/core/widgets/modern_carousel.dart';
import 'package:da_crust_app/data/model/menu_item.dart';
import 'package:da_crust_app/features/menu/widgets/menu_card.dart';
import 'package:flutter/material.dart';

class ModernMenuRow extends StatelessWidget {
  final List<MenuItem> items;

  const ModernMenuRow({super.key, required this.items});

  // 🌟 Card sizing lives here so callers can predict how wide the row will be
  // without duplicating the magic numbers. Kept in sync with the padding /
  // separator defaults ModernCarousel lays the cards out with.
  static const double _mobileCardWidth = 180.0;
  static const double _desktopCardWidth = 220.0;
  static const double _separatorWidth = 16.0;
  static const double _horizontalPadding = 16.0;

  static double cardWidthFor(bool isMobile) =>
      isMobile ? _mobileCardWidth : _desktopCardWidth;

  /// Total width [count] cards need, including the carousel's own padding.
  /// Compare against the available width to tell whether the row will
  /// actually scroll — i.e. whether there is anything more to reveal.
  static double contentWidthFor(int count, bool isMobile) {
    if (count <= 0) return 0;
    return count * cardWidthFor(isMobile) +
        (count - 1) * _separatorWidth +
        _horizontalPadding * 2;
  }

  @override
  Widget build(BuildContext context) {
    // 🌟 1. Grab screen width to dynamically size the cards
    final isMobile = MediaQuery.of(context).size.width < 600;

    // 🌟 2. If mobile, shrink the width to 180 to perfectly match the GridView math!
    final double cardWidth = cardWidthFor(isMobile);

    return ModernCarousel(
      height: isMobile ? 340 : 420,
      scrollAmount: 500,
      separatorWidth: _separatorWidth,
      items: items.map((item) {
        return Align(
          key: ValueKey(item.menuId),
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: cardWidth, // 👇 Use the dynamic width
            child: MenuCard(key: ValueKey(item.menuId), item: item),
          ),
        );
      }).toList(),
    );
  }
}
