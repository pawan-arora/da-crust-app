import 'package:da_crust_app/data/model/menu_item.dart';
import 'package:da_crust_app/features/cart/state/cart_manager.dart';
import 'package:da_crust_app/features/cart/widgets/cart_icon_with_badge.dart';
import 'package:da_crust_app/features/home/widgets/bestsellers_section.dart';
import 'package:da_crust_app/features/home/widgets/restaurant_info_dialog.dart';
import 'package:da_crust_app/features/menu/widgets/category_chips.dart';
import 'package:da_crust_app/features/menu/widgets/menu_grid.dart';
import 'package:da_crust_app/features/menu/widgets/menu_section.dart';
import 'package:da_crust_app/features/ratings/screens/add_review_dialog.dart';
import 'package:da_crust_app/features/ratings/widgets/rating_badge.dart';
import 'package:flutter/material.dart';
import 'package:da_crust_app/features/home/widgets/restaurant_footer.dart';
import 'package:da_crust_app/features/home/widgets/custom_search_bar.dart';
import 'package:da_crust_app/features/home/widgets/restaurant_status_widget.dart';
import 'package:da_crust_app/features/home/widgets/order_time_selector.dart';

class HomeContent extends StatefulWidget {
  final Map<String, List<MenuItem>> grouped;

  const HomeContent({super.key, required this.grouped});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  String selectedCategory = "All";
  String currentSort = "Relevance";
  String searchQuery = "";

  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _resetToHome() {
    _scrollController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
    );

    setState(() {
      selectedCategory = "All";
      searchQuery = "";
    });
  }

  // 🌟 Keeps the dialog functionality, but removes the confetti trigger
  void _openReviewDialog() async {
    await showDialog<bool>(
      context: context,
      builder: (context) => const AddReviewDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 750;

    final categories = ["All", ...widget.grouped.keys];

    final popularItems = widget.grouped.values
        .expand((list) => list)
        .where((item) => item.isPopular)
        .toList();

    List<MenuItem> gridItems = List.from(
      widget.grouped[selectedCategory] ?? [],
    );
    Map<String, List<MenuItem>> filteredGrouped = {};

    if (searchQuery.isNotEmpty) {
      gridItems = gridItems
          .where(
            (item) =>
                item.name.toLowerCase().contains(searchQuery.toLowerCase()),
          )
          .toList();

      for (var entry in widget.grouped.entries) {
        final matches = entry.value
            .where(
              (item) =>
                  item.name.toLowerCase().contains(searchQuery.toLowerCase()),
            )
            .toList();
        if (matches.isNotEmpty) {
          filteredGrouped[entry.key] = matches;
        }
      }
    } else {
      filteredGrouped = widget.grouped;
    }

    if (currentSort == 'Price: Low to High') {
      gridItems.sort((a, b) => a.displayPrice.compareTo(b.displayPrice));
      popularItems.sort((a, b) => a.displayPrice.compareTo(b.displayPrice));
      for (var list in filteredGrouped.values) {
        list.sort((a, b) => a.displayPrice.compareTo(b.displayPrice));
      }
    } else if (currentSort == 'Price: High to Low') {
      gridItems.sort((a, b) => b.displayPrice.compareTo(a.displayPrice));
      popularItems.sort((a, b) => b.displayPrice.compareTo(a.displayPrice));
      for (var list in filteredGrouped.values) {
        list.sort((a, b) => b.displayPrice.compareTo(a.displayPrice));
      }
    } else {
      gridItems.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      popularItems.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      for (var list in filteredGrouped.values) {
        list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      }
    }

    // 🌟 Restored to directly return the CustomScrollView (No Stack)
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverAppBar(
          floating: true,
          snap: true,
          // 👇 1. Reduce height and spacing on mobile
          toolbarHeight: isMobile ? 75 : 90,
          titleSpacing: isMobile ? 16 : 24,
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: _resetToHome,
                  child: Image.asset(
                    'assets/images/logo.png',
                    // 👇 2. Shrink the logo on small screens
                    height: isMobile ? 45 : 70,
                    width: isMobile ? 45 : 70,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              SizedBox(width: isMobile ? 12 : 16),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (context) =>
                                      const RestaurantInfoDialog(),
                                );
                              },
                              child: Text(
                                "Da Crust Pizzeria & Indian Takeaways",
                                // 👇 3. Shrink text slightly on mobile
                                style: TextStyle(
                                  fontSize: isMobile ? 18 : 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 1.0,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (!isMobile)
                          const RatingBadge(), // Hide badge on super small screens to save space
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const RestaurantStatusWidget(),
                        const SizedBox(width: 12),
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: _openReviewDialog,
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.chat_bubble_outline,
                                  color: Colors.white70,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isMobile
                                      ? "Reviews"
                                      : "Leave Feedback", // Shorter text on mobile
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            Center(
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () {},
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 10 : 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(
                        alpha: 0.12,
                      ), // Using modern withValues!
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.person_outline,
                          color: Colors.white,
                          size: 18,
                        ),
                        // 👇 4. Hide the "Welcome, Guest" text on mobile, just keep the icon!
                        if (!isMobile) ...[
                          const SizedBox(width: 8),
                          const Text(
                            "Welcome, Guest",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: isMobile ? 8 : 12),
            Padding(
              padding: EdgeInsets.only(right: isMobile ? 16.0 : 24.0),
              child: const CartIconWithBadge(),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: const AssetImage('assets/images/pizza.jpg'),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.55),
                    BlendMode.darken,
                  ),
                ),
              ),
            ),
          ),
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(isMobile ? 190 : 135),
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              width: double.infinity,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: isMobile
                        ? Column(
                            children: [
                              ListenableBuilder(
                                listenable: CartManager.instance,
                                builder: (context, _) {
                                  return OrderTimeSelector(
                                    scheduledTime:
                                        CartManager.instance.scheduledTime,
                                    onTimeChanged: (newTime) {
                                      CartManager.instance.updateScheduledTime(
                                        newTime,
                                      );
                                    },
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              CustomSearchBar(
                                onChanged: (val) {
                                  setState(() {
                                    searchQuery = val;
                                  });
                                },
                              ),
                            ],
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                flex: 3,
                                child: ListenableBuilder(
                                  listenable: CartManager.instance,
                                  builder: (context, _) {
                                    return OrderTimeSelector(
                                      scheduledTime:
                                          CartManager.instance.scheduledTime,
                                      onTimeChanged: (newTime) {
                                        CartManager.instance
                                            .updateScheduledTime(newTime);
                                      },
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 5,
                                child: CustomSearchBar(
                                  onChanged: (val) {
                                    setState(() {
                                      searchQuery = val;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0, top: 12.0),
                    child: CategoryChips(
                      categories: categories,
                      selected: selectedCategory,
                      onSelected: (value) {
                        setState(() {
                          selectedCategory = value;
                          currentSort = "Relevance";
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (popularItems.isNotEmpty &&
                  selectedCategory == "All" &&
                  searchQuery.isEmpty)
                BestsellersSection(items: popularItems),
              if (selectedCategory != "All")
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Showing ${gridItems.length} Products",
                        style: const TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        height: 36,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(6),
                          color: Colors.white,
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: currentSort,
                            icon: const Icon(
                              Icons.arrow_drop_down,
                              color: Colors.black54,
                            ),
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 13,
                            ),
                            items:
                                [
                                      'Relevance',
                                      'Price: Low to High',
                                      'Price: High to Low',
                                    ]
                                    .map(
                                      (s) => DropdownMenuItem(
                                        value: s,
                                        child: Text("Sort By: $s"),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => currentSort = val);
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              selectedCategory == "All"
                  ? MenuSection(
                      grouped: filteredGrouped,
                      onCategoryTap: (categoryName) {
                        setState(() {
                          selectedCategory = categoryName;
                          currentSort = "Relevance";
                        });
                      },
                    )
                  : MenuGrid(items: gridItems),
              const SizedBox(height: 40),
              if (selectedCategory == "All" && searchQuery.isEmpty)
                const RestaurantFooter(),
            ],
          ),
        ),
      ],
    );
  }
}
