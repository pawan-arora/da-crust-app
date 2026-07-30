import 'package:da_crust_app/core/utils/date_time_utils.dart';
import 'package:da_crust_app/data/model/cart_item.dart';
import 'package:da_crust_app/features/cart/state/cart_manager.dart';
import 'package:da_crust_app/features/cart/widgets/custom_text_field.dart';
import 'package:da_crust_app/features/menu/widgets/safe_menu_image.dart';
import 'package:da_crust_app/features/menu/widgets/item_quantity_stepper.dart';
import 'package:da_crust_app/features/home/services/restaurant_service.dart';
import 'package:flutter/material.dart';

class CartSideSheet extends StatefulWidget {
  const CartSideSheet({super.key});

  static void show(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Cart",
      barrierColor: Colors.black.withAlpha(128),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const CartSideSheet();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position:
              Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
          child: child,
        );
      },
    );
  }

  @override
  State<CartSideSheet> createState() => _CartSideSheetState();
}

class _CartSideSheetState extends State<CartSideSheet> {
  final TextEditingController _noteController = TextEditingController();

  // --- 🌟 NEW: State variables for dynamic location ---
  String _restaurantName = "Da Crust Pizzeria";
  String _pickupAddress = "Loading address...";

  @override
  void initState() {
    super.initState();
    _loadLocationData(); // Fetch instantly when the cart opens
    
    // Pre-fill the controller with the existing note from CartManager!
    _noteController.text = CartManager.instance.orderNote;
  }

  // --- 🌟 NEW: Fetching from your cached service ---
  Future<void> _loadLocationData() async {
    final data = await RestaurantService.instance.fetchRestaurantData();
    if (mounted && data != null) {
      final name = data['name'] ?? "Da Crust Pizzeria & Indian Takeaways";
      final addressMap = data['address'] as Map<String, dynamic>? ?? {};
      final street = addressMap['street'] ?? "20 Diana Street";
      final city = addressMap['city'] ?? "Lumsden";

      setState(() {
        _restaurantName = name;
        _pickupAddress = "$street, $city";
      });
    } else if (mounted) {
      // Safe fallback just in case Firebase fails
      setState(() {
        _restaurantName = "Da Crust Pizzeria & Indian Takeaways";
        _pickupAddress = "20 Diana Street, Lumsden";
      });
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cartWidth = screenWidth > 450 ? 450.0 : screenWidth * 0.85;

    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: Colors.grey.shade50,
        child: SizedBox(
          width: cartWidth,
          height: double.infinity,
          child: ListenableBuilder(
            listenable: CartManager.instance,
            builder: (context, _) {
              final items = CartManager.instance.items;
              final count = CartManager.instance.totalItemCount;

              return Column(
                children: [
                  // --- HEADER ---
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 16.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "YOUR CART ${count > 0 ? '($count)' : ''}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, thickness: 1, color: Colors.grey.shade200),

                  // --- BODY ---
                  Expanded(
                    child: items.isEmpty
                        ? _buildEmptyState(context)
                        : _buildCartList(context, items),
                  ),

                  // --- FOOTER ---
                  if (items.isNotEmpty) _buildFooter(context),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            size: 60,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          const Text(
            "Your cart is empty!",
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: 220,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Back to Menu",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartList(BuildContext context, List<CartItem> items) {
   final time = CartManager.instance.scheduledTime ?? DateTimeUtils.getDefaultPickupTime();
    final displayTime = DateTimeUtils.formatDateTime(time);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // 1. DYNAMIC ITEM LIST
        ...items.map((cartItem) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 20.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SafeMenuImage(
                      imagePath: cartItem.item.imagePath,
                      height: 65,
                      width: 65,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              cartItem.item.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '\$${cartItem.unitPriceAtAddition.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      if (cartItem.selectedSize != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          "Size: ${cartItem.selectedSize}",
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                      ],

                      if (cartItem.selectedSpice != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          "Spice: ${cartItem.selectedSpice}",
                          style: TextStyle(
                            color: Colors.red.shade400, // Makes it pop slightly!
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          InkWell(
                            onTap: () =>
                                CartManager.instance.removeItem(cartItem),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                Icons.delete_outline,
                                size: 18,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 110,
                            child: ItemQuantityStepper(
                              quantity: cartItem.quantity,
                              onIncrement: () =>
                                  CartManager.instance.updateQuantity(
                                    cartItem,
                                    cartItem.quantity + 1,
                                  ),
                              onDecrement: () =>
                                  CartManager.instance.updateQuantity(
                                    cartItem,
                                    cartItem.quantity - 1,
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
          );
        }),

        const Divider(height: 10, thickness: 1, color: Colors.black12),
        const SizedBox(height: 20),

        // --- 🌟 DYNAMIC PICKUP LOCATION DISPLAY ---
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.storefront_outlined,
                size: 20,
                color: Colors.grey.shade700,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Pickup Location",
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _restaurantName, // Displays dynamic name
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _pickupAddress, // Displays dynamic street and city
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12), // Space between boxes
        // --- READ-ONLY TIMING DISPLAY ---
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.access_time, size: 20, color: Colors.grey.shade700),
              const SizedBox(width: 12),
              Text(
                "Pickup Time: ",
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Expanded(
                child: Text(
                  displayTime,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // --- THE "ADD A NOTE" EXPANDING TILE ---
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                iconColor: Colors.black87,
                collapsedIconColor: Colors.black87,
                // --- 1. THE TITLE (What the user clicks) ---
                title: Row(
                  children: [
                    Icon(Icons.edit_note, size: 20, color: Colors.grey.shade700),
                    const SizedBox(width: 12),
                    const Text(
                      "Add a note",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: CustomTextField(
                      controller: _noteController,
                      labelText: "Special Instructions", 
                      hintText: "Special instructions for the kitchen...",
                      isRequired: false,
                      minLines: 2,
                      maxLines: 3,
                      maxLength: 300, 
                      onChanged: (value) => CartManager.instance.updateOrderNote(value), 
                    ),
                  ),
                ],
              ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.receipt_long,
                      size: 18,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "Estimated total",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                Text(
                  "\$${CartManager.instance.totalCartPrice.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                 // final time = CartManager.instance.scheduledTime;
                  // String finalFormattedTime = "ASAP";

                  // if (time != null) {
                  //   final hour = time.hour == 0
                  //       ? 12
                  //       : (time.hour > 12 ? time.hour - 12 : time.hour);
                  //   final ampm = time.hour >= 12 ? 'PM' : 'AM';
                  //   final minute = time.minute.toString().padLeft(2, '0');
                  //   finalFormattedTime =
                  //       "${time.day}/${time.month} at $hour:$minute $ampm";
                  // }
                  CartManager.instance.updateOrderNote(_noteController.text);
                  // 3. Slide over to the new full-page Checkout Screen
                  Navigator.pushNamed(context, '/checkout');
                },
                child: const Text(
                  "Checkout",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
