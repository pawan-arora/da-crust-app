import 'package:da_crust_app/core/widgets/modern_carousel.dart';
import 'package:da_crust_app/features/ratings/models/app_review.dart';
import 'package:da_crust_app/features/ratings/services/review_service.dart';
import 'package:flutter/material.dart';

class ReviewsListDialog extends StatelessWidget {
  const ReviewsListDialog({super.key});

  @override
  Widget build(BuildContext context) {
    // 🌟 1. Detect screen size and set a mobile breakpoint
    final size = MediaQuery.sizeOf(context);
    final isMobile = size.width < 600;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      // 🌟 2. Responsive margins: tight on mobile, spacious on desktop
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : size.width * 0.1, 
        vertical: isMobile ? 24 : size.height * 0.1,
      ), 
      child: Container(
        width: double.maxFinite, 
        // Stops the dialog from stretching awkwardly on ultra-wide monitors
        constraints: const BoxConstraints(maxWidth: 800), 
        // 🌟 3. Responsive inner padding
        padding: EdgeInsets.all(isMobile ? 16 : 32), 
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            Row(
              children: [
                Expanded(
                  child: Text(
                    "Customer Reviews", 
                    // Responsive header font size
                    style: TextStyle(
                      fontSize: isMobile ? 20 : 24, 
                      fontWeight: FontWeight.bold
                    ),
                    overflow: TextOverflow.ellipsis, 
                  ),
                ),
                
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
                  // Slightly taller on desktop to accommodate larger text
                  height: isMobile ? 220 : 260,
                  scrollAmount: isMobile ? size.width * 0.75 : 320,
                  items: reviews.map((review) => _buildReviewCard(context, review, isMobile)).toList(),
                );
              }
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard(BuildContext context, AppReview review, bool isMobile) {
    // 🌟 4. Responsive Card Width: 
    // Desktop: Fixed at 300px. 
    // Mobile: Takes up 75% of the screen so the user sees a "peek" of the next card, letting them know they can swipe!
    final screenWidth = MediaQuery.sizeOf(context).width;
    final cardWidth = isMobile ? screenWidth * 0.75 : 300.0;

    return Container(
      width: cardWidth,
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            review.authorName, 
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 15 : 16)
          ),
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
                style: TextStyle(
                  fontSize: isMobile ? 13 : 14, 
                  color: Colors.grey.shade800, 
                  height: 1.4
                ),
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