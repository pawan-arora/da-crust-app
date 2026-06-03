import 'package:flutter/material.dart';
import '../models/app_review.dart';
import '../services/review_service.dart';
import '../screens/reviews_list_dialog.dart';

class RatingBadge extends StatelessWidget {
  const RatingBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AppReview>>(
      stream: ReviewService.instance.getReviewsStream(),
      builder: (context, snapshot) {
        double average = 0.0;
        int count = 0;

        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          final reviews = snapshot.data!;
          count = reviews.length;
          final totalStars = reviews.fold(0, (sum, review) => sum + review.rating);
          average = totalStars / count;
        }

        // 🌟 If there are no reviews, render absolutely nothing!
        if (count == 0) {
          return const SizedBox.shrink();
        }

        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              showDialog(context: context, builder: (context) => const ReviewsListDialog());
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                // 🌟 Replaced deprecated withOpacity with withAlpha (0.4 * 255 ≈ 102)
                color: Colors.black.withAlpha(102),
                borderRadius: BorderRadius.circular(12),
                // 🌟 Replaced deprecated withOpacity with withAlpha (0.5 * 255 ≈ 128)
                border: Border.all(color: Colors.amber.withAlpha(128)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    average.toStringAsFixed(1), 
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.star, color: Colors.amber, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    "($count)", 
                    style: const TextStyle(color: Colors.white70, fontSize: 13, decoration: TextDecoration.underline)
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}