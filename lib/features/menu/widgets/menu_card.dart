import 'package:da_crust_app/core/builders/image_preload_builder.dart';
import 'package:da_crust_app/features/cart/state/cart_manager.dart';
import 'package:da_crust_app/data/model/menu_item.dart';
import 'package:da_crust_app/features/menu/widgets/menu_card_image_header.dart';
import 'package:da_crust_app/features/menu/widgets/size_selection_dialog.dart';
import 'package:da_crust_app/features/menu/widgets/skeleton_card.dart';
import 'package:da_crust_app/features/menu/widgets/item_quantity_stepper.dart';
import 'package:da_crust_app/features/menu/widgets/spice_selection_dialog.dart';
import 'package:flutter/material.dart';

class MenuCard extends StatefulWidget {
  final MenuItem item;
  
  // 🌟 1. Removed the hardcoded originalPrice here.
  
   const MenuCard({super.key, required this.item});

  @override
  State<MenuCard> createState() => _MenuCardState();
}

class _MenuCardState extends State<MenuCard> {
  bool _isHovered = false;

  void _showSizeSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => SizeSelectionDialog(item: widget.item),
    );
  }

  void _showSpiceSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => SpiceSelectionDialog(item: widget.item),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 🌟 2. Switched to use the database-driven fields from the MenuItem model
    bool hasDiscount = widget.item.isDiscounted && 
                       widget.item.originalPrice != null && 
                       widget.item.originalPrice! > widget.item.displayPrice;
                       
    bool requiresCustomization = widget.item.sizes.isNotEmpty || widget.item.spiceLevels.isNotEmpty;

    String customizationText = "";
    if (widget.item.sizes.isNotEmpty && widget.item.spiceLevels.isNotEmpty) {
      customizationText = "Size & Spice";
    } else if (widget.item.sizes.isNotEmpty) {
      customizationText = "${widget.item.sizes.length} Sizes";
    } else if (widget.item.spiceLevels.isNotEmpty) {
      customizationText = "Spice Level";
    }

    return ImagePreloadBuilder(
      imagePath: widget.item.imagePath,
      builder: (context, isLoading) {
        
        if (isLoading) {
          return const SkeletonCard(availableHeight: 330);
        }

        return MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            transform: Matrix4.translationValues(0, _isHovered ? -8.0 : 0.0, 0),
            child: SizedBox(
              width: 280,
              height: 390,
              child: Card(
                clipBehavior: Clip.antiAlias,
                color: Theme.of(context).cardColor,
                elevation: _isHovered ? 8 : 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    
                    // 🌟 3. Removed the originalPrice parameter from the header widget
                    MenuCardImageHeader(
                      item: widget.item,
                    ),

                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    widget.item.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                if (widget.item.foodLabel != null && widget.item.foodLabel!['url'] != null) ...[
                                  const SizedBox(width: 8),
                                  Tooltip(
                                    message: widget.item.foodLabel!['type']?.toString() ?? "",
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.white, borderRadius: BorderRadius.circular(4),
                                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 4, offset: const Offset(0, 2))],
                                      ),
                                      child: Image.network(
                                        widget.item.foodLabel!['url'].toString(),
                                        width: 16, height: 16, fit: BoxFit.contain,
                                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),

                            if (widget.item.description.isNotEmpty) ...[
                              InkWell(
                                onTap: widget.item.description.length > 50 ? () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      title: Text(widget.item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      content: SingleChildScrollView(child: Text(widget.item.description, style: const TextStyle(height: 1.5, fontSize: 14))),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: Text("Close", style: TextStyle(color: Theme.of(context).primaryColor)),
                                        ),
                                      ],
                                    ),
                                  );
                                } : null,
                                child: Tooltip(
                                  message: widget.item.description,
                                  waitDuration: const Duration(milliseconds: 400),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.item.description,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.3),
                                      ),
                                      if (widget.item.description.length > 50)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 2.0),
                                          child: Text("Read more", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Theme.of(context).primaryColor)),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),

                            Row(
                              children: [
                                Text(
                                  '\$${widget.item.displayPrice.toStringAsFixed(2)}',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.secondary),
                                ),
                                if (hasDiscount) ...[
                                  const SizedBox(width: 8),
                                  // 🌟 4. Now pulling the strikethrough price from the item model
                                  Text('\$${widget.item.originalPrice!.toStringAsFixed(2)}', style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey, fontSize: 12)),
                                ],
                              ],
                            ),

                            if (requiresCustomization) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                decoration: BoxDecoration(color: Theme.of(context).primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.tune, size: 12, color: Theme.of(context).primaryColor),
                                    const SizedBox(width: 4),
                                    Text(customizationText, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Theme.of(context).primaryColor)),
                                  ],
                                ),
                              ),
                            ],

                            const Spacer(),

                            ListenableBuilder(
                              listenable: CartManager.instance,
                              builder: (context, _) {
                                final cartItems = CartManager.instance.items.where((i) => i.item.menuId == widget.item.menuId).toList();
                                final quantityInCart = cartItems.fold(0, (sum, i) => sum + i.quantity);

                                if (!widget.item.isAvailable) {
                                  return SizedBox(width: double.infinity, height: 36, child: ElevatedButton(onPressed: null, child: const Text("Sold Out")));
                                }

                                if (requiresCustomization) {
                                  return SizedBox(
                                    width: double.infinity, height: 36,
                                    child: OutlinedButton(
                                      style: _addButtonStyle(context),
                                      onPressed: () => {
                                        if (widget.item.sizes.isNotEmpty) {
                                          _showSizeSelectionDialog(context)
                                        } else if (widget.item.spiceLevels.isNotEmpty) {
                                          _showSpiceSelectionDialog(context)
                                        }
                                      },
                                      child: const Text("Customize", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    ),
                                  );
                                }

                                if (quantityInCart == 0) {
                                  return SizedBox(
                                    width: double.infinity, height: 36,
                                    child: OutlinedButton(
                                      style: _addButtonStyle(context),
                                      onPressed: () {
                                        CartManager.instance.addItem(widget.item, quantity: 1);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text("${widget.item.name} added to cart!"), behavior: SnackBarBehavior.floating,
                                            backgroundColor: Colors.green.shade600, duration: const Duration(seconds: 2),
                                          ),
                                        );
                                      },
                                      child: const Text("Add", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    ),
                                  );
                                } else {
                                  return SizedBox(
                                    width: double.infinity,
                                    child: ItemQuantityStepper(
                                      quantity: quantityInCart,
                                      onIncrement: () => CartManager.instance.addItem(widget.item, quantity: 1),
                                      onDecrement: () => CartManager.instance.updateQuantity(cartItems.first, cartItems.first.quantity - 1),
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  ButtonStyle _addButtonStyle(BuildContext context) {
    return OutlinedButton.styleFrom(
      foregroundColor: Theme.of(context).primaryColor,
      side: BorderSide(color: Theme.of(context).primaryColor, width: 1.5),
      padding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}