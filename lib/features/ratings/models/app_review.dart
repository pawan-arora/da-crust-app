import 'package:cloud_firestore/cloud_firestore.dart';
// 🌟 Removed the 'intl' import entirely
import 'package:timezone/timezone.dart' as tz;
import 'package:da_crust_app/core/utils/date_time_utils.dart'; 

class AppReview {
  final String id;
  final String authorName;
  final int rating;
  final String comment;
  final tz.TZDateTime createdAt;

  AppReview({
    required this.id,
    required this.authorName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory AppReview.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    tz.TZDateTime parsedNzTime;
    if (data['createdAt'] != null) {
      final utcDate = (data['createdAt'] as Timestamp).toDate();
      final nzLocation = DateTimeUtils.getNzTime().location;
      parsedNzTime = tz.TZDateTime.from(utcDate, nzLocation);
    } else {
      parsedNzTime = DateTimeUtils.getNzTime();
    }

    return AppReview(
      id: doc.id,
      authorName: data['authorName'] ?? 'Anonymous',
      rating: data['rating'] ?? 5,
      comment: data['comment'] ?? '',
      createdAt: parsedNzTime,
    );
  }

  // 🌟 THE FIX: Relying purely on your central Date/Time logic!
  String get formattedDate {
    return DateTimeUtils.formatDateTime(createdAt);
  }
}