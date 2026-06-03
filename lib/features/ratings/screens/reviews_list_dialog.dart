import 'package:da_crust_app/core/widgets/modern_carousel.dart';
import 'package:da_crust_app/features/ratings/models/app_review.dart';
import 'package:da_crust_app/features/ratings/services/review_service.dart';
import 'package:flutter/material.dart';

class ReviewsListDialog extends StatelessWidget {
  const ReviewsListDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        // 🌟 THE FIX 1: Forces the dialog to respect the boundary, stopping the button from flying off-screen
        width: double.maxFinite, 
        constraints: const BoxConstraints(maxWidth: 800), 
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            // 🌟 THE FIX 2: A bulletproof Header Row
            Row(
              children: [
                const Expanded(
                  child: Text(
                    "Customer Reviews", 
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis, // Prevents text overflow if screen gets too small
                  ),
                ),
                
                // Enhanced, highly visible close button
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.black87, size: 20), 
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Close',
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 16),
            
            StreamBuilder<List<AppReview>>(
              stream: ReviewService.instance.getReviewsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(height: 220, child: Center(child: CircularProgressIndicator()));
                }
                
                final reviews = snapshot.data ?? [];
                
                if (reviews.isEmpty) {
                  return const SizedBox(height: 220, child: Center(child: Text("No reviews yet. Be the first!")));
                }

                return ModernCarousel(
                  height: 220,
                  scrollAmount: 320,
                  items: reviews.map((review) => _buildReviewCard(review)).toList(),
                );
              }
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard(AppReview review) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(review.authorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 4),
          Row(
            children: List.generate(5, (starIndex) => Icon(
              starIndex < review.rating ? Icons.star : Icons.star_border,
              color: Colors.amber, size: 16,
            )),
          ),
          const SizedBox(height: 12),
          
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Text(
                review.comment,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade800, height: 1.4),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(review.formattedDate, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}