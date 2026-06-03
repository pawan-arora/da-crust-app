import 'package:flutter/material.dart';

class SkeletonCard extends StatelessWidget {
  const SkeletonCard({
    super.key,
    required this.availableHeight,
  });

  final double availableHeight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image Placeholder
        Container(
          height: availableHeight * 0.40,
          color: Colors.grey.shade300,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title Placeholder
                Container(height: 18, width: 140, color: Colors.grey.shade300),
                const SizedBox(height: 8),
                // Price Placeholder
                Container(height: 16, width: 80, color: Colors.grey.shade300),
                const Spacer(),
                // Button Placeholder
                Container(
                  height: 36,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}