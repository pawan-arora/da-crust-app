import 'package:da_crust_app/core/constants/app_assets.dart';
import 'package:da_crust_app/data/model/menu_item.dart';
import 'package:da_crust_app/features/cart/state/cart_manager.dart';
import 'package:da_crust_app/features/cart/widgets/cart_icon_with_badge.dart';
import 'package:da_crust_app/features/home/services/restaurant_service.dart';
import 'package:da_crust_app/features/home/widgets/bestsellers_section.dart';
import 'package:da_crust_app/features/home/widgets/category_chips_header.dart';
import 'package:da_crust_app/features/home/widgets/restaurant_info_dialog.dart';
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
  final GlobalKey<CustomSearchBarState> _searchKey =
      GlobalKey<CustomSearchBarState>();
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

    // Clear the search bar
    _searchKey.currentState?.clear();

    setState(() {
      selectedCategory = "All";
      searchQuery = "";
    });
  }

  void _openReviewDialog() async {
    await showDialog<bool>(
      context: context,
      builder: (context) => const AddReviewDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    // 🌟 THE FIX: We abandon percentage math for the bounding boxes.
    // The wrapping content needs a guaranteed absolute height to never clip!
    final safeToolbarHeight = isMobile ? 135.0 : 105.0;
    // final safeBottomHeight = isMobile ? 175.0 : 135.0;
    final horizontalPadding = isMobile ? 16.0 : 24.0;

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

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverAppBar(
          floating: true,
          snap: true,
          pinned: false,
          elevation: 0, // ← add
          scrolledUnderElevation: 0, // ← add
          surfaceTintColor: Colors.transparent, // ← add
          shadowColor: Colors.transparent, // ← add
          forceElevated: false,
          // 👇 Using the guaranteed safe height
          toolbarHeight: safeToolbarHeight,
          titleSpacing: isMobile ? 12 : 24,
          automaticallyImplyLeading: false,
          title: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: _resetToHome,
                  child: Padding(
                    // 👇 Give the logo a tiny push down so it aligns with the title
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Image.asset(
                      AppAssets.logo,
                      height: isMobile ? 45 : 70,
                      width: isMobile ? 45 : 70,
                      fit: BoxFit.contain,
                    ),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Flexible(
                          child: Text(
                            RestaurantService.instance.name,
                            style: TextStyle(
                              fontSize: isMobile ? 16 : 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.0,
                              height: 1.1,
                            ),
                            maxLines: isMobile ? 2 : 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!isMobile) ...[
                          const SizedBox(width: 12),
                          const RatingBadge(),
                        ],
                      ],
                    ),
                    SizedBox(height: isMobile ? 8 : 6),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8, // Tighter horizontal gap
                      runSpacing:
                          4, // Tighter vertical gap to prevent pushing the bounds
                      children: [
                        const RestaurantStatusWidget(),
                        if (isMobile) const RatingBadge(),
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: _openReviewDialog,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.chat_bubble_outline,
                                  color: Colors.white70,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isMobile ? "Reviews" : "Leave Feedback",
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
                        // ── View Details button (restaurant info) ──
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) =>
                                    const RestaurantInfoDialog(),
                              );
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons
                                      .storefront_outlined, // ← clearer “about the restaurant” icon
                                  color: Colors.white70,
                                  size: 15,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  isMobile ? "Details" : "View Details",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
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
                  onTap: () {
                    if (isMobile) {
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                            "Welcome, Guest!",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          backgroundColor: Colors.black87,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          margin: const EdgeInsets.only(
                            bottom: 20,
                            left: 80,
                            right: 80,
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 10 : 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
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
              padding: EdgeInsets.only(right: horizontalPadding),
              child: const CartIconWithBadge(),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: const AssetImage(AppAssets.pizzaBackground),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withValues(alpha: 0.55),
                    BlendMode.darken,
                  ),
                ),
              ),
            ),
          ),
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(
              isMobile ? 95.0 : 70.0,
            ), // ← smaller now
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 8,
              ),
              child: isMobile
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ListenableBuilder(
                          listenable: CartManager.instance,
                          builder: (context, _) {
                            return OrderTimeSelector(
                              scheduledTime: CartManager.instance.scheduledTime,
                              onTimeChanged: (newTime) {
                                CartManager.instance.updateScheduledTime(
                                  newTime,
                                );
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        CustomSearchBar(
                          key: _searchKey,
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
                                  CartManager.instance.updateScheduledTime(
                                    newTime,
                                  );
                                },
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 5,
                          child: CustomSearchBar(
                            key: _searchKey,
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
          ),
        ),
        SliverPersistentHeader(
          pinned: true,
          delegate: CategoryChipsHeader(
            categories: categories,
            selected: selectedCategory,
            onSelected: (value) {
              setState(() {
                selectedCategory = value;
                currentSort = "Relevance";
              });
            },
            horizontalPadding: horizontalPadding,
            isMobile: isMobile,
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
                  // 👇 Also applying the dynamic padding here for perfect alignment
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: 8.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        // 🌟 FIX 4: Wrapped in FittedBox to dynamically shrink text instead of clipping!
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Showing ${gridItems.length} Products",
                            style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.w600,
                              fontSize: isMobile ? 14 : 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
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
                                        child: Text(
                                          isMobile
                                              ? s.replaceFirst('Price: ', '')
                                              : "Sort By: $s",
                                        ),
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
