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
    final isMobile = MediaQuery.of(context).size.width < 600;
    final primary = Theme.of(context).primaryColor;

    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: grouped.entries.map((entry) {
        
        // Safety check: Don't render a category if it's empty
        if (entry.value.isEmpty) return const SizedBox.shrink();

        return Padding(
          key: ValueKey(entry.key),
          padding: const EdgeInsets.only(bottom: 24.0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Only offer "View all" when the carousel actually has more
              // items than fit on screen. A row that already shows everything
              // has nothing to reveal, so the button would be noise.
              final hasMoreToShow =
                  ModernMenuRow.contentWidthFor(entry.value.length, isMobile) >
                  constraints.maxWidth;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- CATEGORY HEADER ---
                  // The button sits right beside the title rather than pinned
                  // to the far edge, so it stays visually attached to the row
                  // it belongs to no matter how few cards are in it.
                  InkWell(
                    onTap: hasMoreToShow ? () => onCategoryTap(entry.key) : null,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              entry.key,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                            ),
                          ),
                          if (hasMoreToShow) ...[
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "View all ${entry.value.length}",
                                    style: TextStyle(
                                      color: primary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: isMobile ? 12 : 13,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    size: isMobile ? 10 : 11,
                                    color: primary,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // --- THE MODERN CAROUSEL ---
                  ModernMenuRow(key: ValueKey(entry.key), items: entry.value),

                ],
              );
            },
          ),
        );
      }).toList(),
    );
  }
}
