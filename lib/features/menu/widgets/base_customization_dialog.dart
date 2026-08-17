import 'package:da_crust_app/data/model/menu_item.dart';
import 'package:da_crust_app/features/menu/widgets/safe_menu_image.dart';
import 'package:flutter/material.dart';

class BaseCustomizationDialog extends StatelessWidget {
  final MenuItem item;
  final List<Widget> content; 
  final Widget bottomButton;  

  const BaseCustomizationDialog({
    super.key,
    required this.item,
    required this.content,
    required this.bottomButton,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final responsiveWidth = screenWidth > 600 ? 500.0 : screenWidth * 0.9;
    final responsiveImageHeight = (screenHeight * 0.25).clamp(150.0, 260.0);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.all(20),
      child: SizedBox(
        width: responsiveWidth,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                children: [
                  SafeMenuImage(imagePath: item.imagePath, height: responsiveImageHeight),
                  Positioned(
                    top: 12, right: 12,
                    child: CircleAvatar(
                      backgroundColor: Colors.black.withValues(alpha: 0.5),
                      radius: 16,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.close, color: Colors.white, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    ...content,
                    const SizedBox(height: 16),
                    bottomButton,
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 🌟 THE FIX: Replaced InkWell with native IconButton for guaranteed Web clicks!
class DialogQuantityStepper extends StatelessWidget {
  final int quantity;
  final VoidCallback? onDecrement;
  final VoidCallback onIncrement;

  const DialogQuantityStepper({
    super.key,
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove, size: 18),
            onPressed: onDecrement, // Automatically disables and greys out if null!
            color: Colors.black87,
            disabledColor: Colors.grey.shade400,
          ),
          SizedBox(
            width: 20,
            child: Text('$quantity', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 18),
            onPressed: onIncrement,
            color: Colors.black87,
          ),
        ],
      ),
    );
  }
}