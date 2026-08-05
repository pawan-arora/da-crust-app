import 'package:da_crust_app/features/menu/widgets/category_chips.dart';
import 'package:flutter/material.dart';

class CategoryChipsHeader extends SliverPersistentHeaderDelegate {
  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelected;
  final double horizontalPadding;
  final bool isMobile;

  CategoryChipsHeader({
    required this.categories,
    required this.selected,
    required this.onSelected,
    required this.horizontalPadding,
    required this.isMobile,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Padding(
        padding: EdgeInsets.only(
          left: horizontalPadding,
          right: horizontalPadding,
          top: isMobile ? 6 : 4,
          bottom: isMobile ? 8 : 10,
        ),
        child: CategoryChips(
          categories: categories,
          selected: selected,
          onSelected: onSelected,
        ),
      ),
    );
  }

  @override
  double get maxExtent => isMobile ? 70 : 76;

  @override
  double get minExtent => isMobile ? 70 : 76;

  @override
  bool shouldRebuild(covariant CategoryChipsHeader oldDelegate) {
    return oldDelegate.selected != selected ||
        oldDelegate.categories != categories;
  }
}
