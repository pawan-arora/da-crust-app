import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import '../models/app_review.dart';

class ReviewService {
  static final ReviewService instance = ReviewService._internal();
  ReviewService._internal();

  final CollectionReference _reviewsRef = FirebaseFirestore.instance.collection('reviews');

  Stream<List<AppReview>> getReviewsStream() {
    return _reviewsRef.orderBy('createdAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => AppReview.fromFirestore(doc)).toList();
    });
  }

  // 🌟 UPDATED: Now calls the Cloud Function with the token
  Future<void> submitReview({
    required String name,
    required int rating,
    required String comment,
    required String recaptchaToken, // 🌟 Requires the token
  }) async {
    try {
      final callable = FirebaseFunctions.instanceFor(region: 'australia-southeast1')
          .httpsCallable('submitReviewWithCaptcha');

      await callable.call({
        'name': name,
        'rating': rating,
        'comment': comment,
        'recaptchaToken': recaptchaToken,
      }).timeout(const Duration(seconds: 15));

    } catch (e) {
       debugPrint("General Payment error: ${e.toString()}");
      throw Exception("Could not publish review. Please try again.");
    }
  }
}